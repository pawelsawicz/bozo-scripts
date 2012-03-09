require 'uglifier'
require 'minification'

module Bozo::Hooks

  class JsMinification < Bozo::Hooks::Minification

    def initialize
      super
      exclude "**/*.min.js"
    end

    def file_extension
      :js
    end

    def minify(js)
      Uglifier.compile js
    end

  end

end