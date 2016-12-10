require_relative 'abstract_translator'
require_relative 'translator_helper'

module Translators
  #
  # SplashKit Swift code generator
  #
  class Swift < AbstractTranslator
    include TranslatorHelper

    def initialize(data, logging = false)
      super(data, logging)
    end

    def render_templates
      {
        'splashkit.swift' => read_template('splashkit.swift')
        'module.modulemap' => read_template('module.modulemap')
      }
    end

    #=== internal ===

    SWIFT_IDENTIFIER_CASES = {
      types:      :pascal_case,
      functions:  :camel_case,
      variables:  :camel_case,
      constants:  :camel_case
    }
    DIRECT_TYPES = {}
    SK_TYPES_TO_PASCAL_TYPES = {
      'int'             => 'Int',
      'short'           => 'Int16',
      'long'            => 'Int',
      'float'           => 'Float',
      'double'          => 'Double',
      'byte'            => 'Character',
      'char'            => 'Character',
      'unsigned char'   => 'UInt8',
      'unsigned short'  => 'Int16',
      'unsigned int'    => 'UInt32',
      'unsigned long'   => 'UInt64',
      'bool'            => 'Bool'
    }
    SK_TYPES_TO_LIB_TYPES = {
      'int'             => 'CInt',
      'short'           => 'CShort',
      'long'            => 'CLong',
      'float'           => 'CFloat',
      'double'          => 'CDouble',
      'byte'            => 'CChar',
      'char'            => 'CChar',
      'unsigned char'   => 'CUnsignedChar',
      'unsigned int'    => 'CUnsignedInt',
      'unsigned short'  => 'CUnsignedShort',
      'unsigned long'   => 'CUnsignedLong',
      'bool'            => 'CBool',
      'enum'            => 'CInt'
    }

    def type_exceptions(type_data, type_conversion_fn, opts = {})
      # Handle char* as PChar
      return 'UnsafePointer<Character>' if char_pointer?(type_data)
      # Handle void * as Pointer
      return 'UnsafeRawPointer' if void_pointer?(type_data)
      # Handle function pointers
      #return type_data[:type].type_case if function_pointer?(type_data)
      # Handle generic pointer
      #return "^#{type}" if type_data[:is_pointer]
      # Handle vectors as Array of <T>
      # if vector_type?(type_data)
      #   return "__sklib_vector_#{type_data[:type_parameter]}" if opts[:is_lib]
      #   return "ArrayOf#{send(type_conversion_fn, type_data[:type_parameter])}"
      # end
      # No exception for this type
      return nil
    end

    #
    # Generate a Pascal type signature from a SK function
    #
    def signature_syntax(function, function_name, parameter_list, return_type, opts = {})
      func_suffix = " -> #{return_type}" if is_func?(function)
      "#{declaration} #{function_name}(#{parameter_list})#{func_suffix}"
    end

    #
    # Convert a list of parameters to a Pascal parameter list
    # Use the type conversion function to get which type to use
    # as this function is used to for both Library and Front-End code
    #
    def parameter_list_syntax(parameters, type_conversion_fn, opts = {})
      parameters.map do |param_name, param_data|
        type = send(type_conversion_fn, param_data)
        if param_data[:is_reference]
          var = param_data[:is_const] ? 'TODO ' : 'inout '
        end
        "#{param_name.variable_case}: #{var}#{type}"
      end.join(', ')
    end

    #
    # Joins the argument list using a comma
    #
    def argument_list_syntax(arguments)
      # TODO: & for inout arguments
      arguments.join(', ')
    end
  end
end
