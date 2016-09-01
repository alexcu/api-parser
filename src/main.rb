#!/usr/bin/env ruby
require          'optparse'
require          'fileutils'
require_relative 'parser'
require_relative 'translators/sklibc'
require_relative 'translators/pascal'

# Required to run
options = {
  translators: [],
  src: nil,
  out: nil,
  validate_only: false
}

# Options parse block
opt_parser = OptionParser.new do |opts|
  # Translators we can use
  avaliable_translators =
    Translators.constants
               .select { |c| Class === Translators.const_get(c) }
               .select { |c| c != :AbstractTranslator }
               .map { |t| [t.upcase, Translators.const_get(t)] }
               .to_h
  # Setup
  help = <<-EOS
Usage: parse.rb --input /path/to/splashkit[/coresdk/src/coresdk/file.h]
                [--generate GENERATOR[,GENERATOR ... ]
                [--output /path/to/write/output/to]
                [--validate]
EOS
  opts.banner = help
  opts.separator ''
  opts.separator 'Required:'
  # Source file
  help = <<-EOS
Source header file or SplashKit CoreSDK directory
EOS
  opts.on('-i', '--input SOURCE', help) do |input|
    options[:src] = input
    options[:out] = input + '/out' unless input.end_with? '.h'
  end
  # Generate using translator
  help = <<-EOS
Comma separated list of translators to run on the file(s).
EOS
  opts.on('-g', '--generate TRANSLATOR[,TRANSLATOR ... ]', help) do |translators|
    parsed_translators = translators.split(',')
    options[:translators] = parsed_translators.map do |translator|
      translator_class = avaliable_translators[translator.upcase.to_sym]
      if translator_class.nil?
        raise OptionParser::InvalidOption, "#{translator} - Unknown translator #{translator}"
      end
      translator_class
    end
  end
  # Output file(s)
  help = <<-EOS
Directory to write output to (defaults to /path/to/splashkit/out)
EOS
  opts.on('-o', '--output OUTPUT', help) do |out|
    options[:out] = out
  end
  # Validate only (don't generate)
  help = <<-EOS
Validate HeaderDoc only to parse without translating
EOS
  opts.on('-v', '--validate', help) do
    options[:validate_only] = true
  end
  opts.separator ''
  opts.separator 'Translators:'
  avaliable_translators.keys.each { |translator| opts.separator "    * #{translator}" }
end
# Parse block
begin
  opt_parser.parse!
  mandatory = [:src]
  # Add translators to mandatory if not validating
  mandatory << :translators unless options[:validate_only]
  missing = mandatory.select { |param| options[param].nil? }
  raise OptionParser::MissingArgument, 'Arguments missing' unless missing.empty?
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  exit 1
end
# Run block
begin
  raise 'headerdoc2html is not installed!' unless Parser.headerdoc_installed?
  parsed = Parser.parse(options[:src])
  options[:translators].each do |translator_class|
    translator = translator_class.new(parsed, options[:src])
    out = translator.execute
    if options[:validate_only]
      puts 'Parser succeeded with no errors 🎉'
    elsif options[:out]
      out.each do |filename, contents|
        output = "#{options[:out]}/#{translator.name}/#{filename}"
        FileUtils.mkdir_p File.dirname output
        puts "Writing output to #{output}..."
        File.write output, contents
      end
    end
  end
rescue Parser::Error
  puts $!.to_s
  exit 1
end