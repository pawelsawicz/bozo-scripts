require "yui/compressor"
require 'minification'

module Bozo::Hooks

  class CssMinification < Bozo::Hooks::Minification

    def initialize
      super
      exclude "**/*.min.css"
      @compressor = YUI::CssCompressor.new
    end

    def file_extension
      :css
    end

    def minify(css)
      @compressor.compress css
    end

  end

end