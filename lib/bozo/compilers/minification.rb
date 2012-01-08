require 'uglifier'
require "yui/compressor"

module Bozo::Compilers

  class Minification

    def initialize
      @types = Hash.new
      minify :js
      minify :css
      @include_version = false
    end

    # add the type of files to minify
    #
    # @param type[:symbol]
    #     type of the files to minify
    # @param exclude[Array]
    #     array containing files to exclude
    def minify(type, exclude = nil)
      exclude = ["**/*.min.#{type}"] if exclude.nil?
      @types[type] = exclude
    end

    # include the version number in the minified file name
    def include_version_number
      @include_version = true
    end

    def execute
      minify_css if @types.include?(:css)
      minify_js if @types.include?(:js)
    end

    private

    def minify_js
      files = get_minify_files(:js)
      exclude = get_exclusion_files(:js, @types[:js])

      files.each do |f|
        a = Uglifier.compile(File.read(f)) unless exclude.include?(f)
        a = File.read(f) if exclude.include?(f)
        File.open(output_filename(f), 'w') {|t| t.write(a) }
      end
    end

    def minify_css
      compressor = YUI::CssCompressor.new

      files = get_minify_files(:css)
      exclude = get_exclusion_files(:css, @types[:css])

      files.each do |f|
        css = File.read(f)
        a = compressor.compress css unless exclude.include?(f)
        a = css if exclude.include?(f)
        File.open(output_filename(f), 'w') {|t| t.write(a) }
      end
    end

    def get_minify_files(type)
      file_matcher = File.expand_path(File.join('src', '**', "*.#{type}"))
      Dir[file_matcher]
    end

    def get_exclusion_files(type, exclude)
      file_matcher = File.expand_path(File.join('src', exclude))
      Dir[file_matcher]
    end

    def output_filename(original_path)
      tmp = File.join('temp', 'web')
      FileUtils.mkdir_p tmp
      output_path = File.join(tmp, File.basename(original_path, '.*'))
      output_path = "#{output_path}-#{version}" if @include_version
      output_path = "#{output_path}#{File.extname(original_path)}"
      output_path
    end

  end

end