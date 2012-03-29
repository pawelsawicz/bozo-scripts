require "sass"
require_relative 'minification'

module Bozo::Hooks

  class CssMinification < Bozo::Hooks::Minification

    def initialize
      super
      exclude "**/*.min.css"
    end

    def file_extension
      :css
    end

    def minify(css)
      engine = Sass::Engine.new(css, :style => :compressed)
      engine.render
    end

  end

end