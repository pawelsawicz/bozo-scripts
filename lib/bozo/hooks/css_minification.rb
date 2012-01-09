require "yui/compressor"
require 'minification'

module Bozo::Hooks

  class CssMinification < Bozo::Hooks::Minification

    def initialize
      super
      exclude "**/*.min.css"
    end

    def pre_package
      compressor = YUI::CssCompressor.new

      files = get_files(:css)
      exclude = get_exclusion_files()

      files.each do |f|
        css = File.read(f)
        minified = compressor.compress css unless exclude.include?(f)
        minified = css if exclude.include?(f)
        File.open(output_filename(f), 'w') {|t| t.write(minified) }
      end
    end

  end

end