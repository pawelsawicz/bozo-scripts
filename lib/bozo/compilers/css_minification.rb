require "yui/compressor"
require 'minification'

module Bozo::Compilers

  class CssMinification < Bozo::Compilers::Minification

    def initialize
      super
      exclude "**/*.min.css"
    end

    def execute
      compressor = YUI::CssCompressor.new

      files = get_files(:css)
      exclude = get_exclusion_files()

      files.each do |f|
        css = File.read(f)
        a = compressor.compress css unless exclude.include?(f)
        a = css if exclude.include?(f)
        File.open(output_filename(f), 'w') {|t| t.write(a) }
      end
    end

  end

end