require 'uglifier'
require 'minification'

module Bozo::Compilers

  class JsMinification < Bozo::Compilers::Minification

    def initialize
      super
      exclude "**/*.min.js"
    end

    def execute
      files = get_files(:js)
      exclude = get_exclusion_files()

      files.each do |f|
        minified = Uglifier.compile(File.read(f)) unless exclude.include?(f)
        minified = File.read(f) if exclude.include?(f)
        File.open(output_filename(f), 'w') {|t| t.write(minified) }
      end
    end

  end

end