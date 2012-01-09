module Bozo::Hooks

  class Minification

    def initialize
      @exclude = []
      @include_version = false
    end

    # adds an exclusion pattern of files to not minify
    #
    # @param exclude[String]
    #     value containing pattern to exclude
    def exclude(exclude = nil)
      @exclude << exclude unless exclude.nil?
      @exclude
    end

    # include the version number in the minified file name
    def include_version_number
      @include_version = true
    end

    private

    # gets all the files of the specified type
    #
    # @param type[:symbol]
    #     the file extension type
    def get_files(type)
      file_matcher = File.expand_path(File.join('src', '**', "*.#{type}"))
      Dir[file_matcher]
    end

    # gets all the files that should be excluded from minification
    def get_exclusion_files()
      files_to_exclude = []
      @exclude.each do |e|
        file_matcher = File.expand_path(File.join('src', e))
        files_to_exclude << Dir[file_matcher]
      end

      files_to_exclude.flatten!
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