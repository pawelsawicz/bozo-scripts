module Bozo::Hooks

  class Minification

    def initialize
      @exclude = []
      @include_version = false
      @include_min_extension = false
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

    # include the '.min' extension on the file name
    def include_min_extension
      @include_min_extension = true
    end

    def pre_package
      files = get_files(file_extension)
      exclude = get_exclusion_files()

      files.each do |f|
        content = File.read(f)
        content = minify content unless exclude.include? f

        File.open(output_filename(f), 'w') { |t| t.write(content) }
      end
    end

    protected

    # Minifies the content.
    #
    # @param content[String]
    def minify(content)
      content
    end

    private

    # gets all the files of the specified type
    #
    # @param type[:symbol]
    #     the file extension type
    def get_files(type)
      file_matcher = File.expand_path(File.join('temp', '**', "*.#{type}"))
      Dir[file_matcher]
    end

    # gets all the files that should be excluded from minification
    def get_exclusion_files()
      files_to_exclude = []
      @exclude.each do |e|
        file_matcher = File.expand_path(File.join('temp', e))
        files_to_exclude << Dir[file_matcher]
      end

      files_to_exclude.flatten!
    end

    def output_filename(original_path)
      output_path = File.join(File.dirname(original_path), File.basename(original_path, '.*'))
      output_path = "#{output_path}-#{version}" if @include_version
      output_path = "#{output_path}.min" if @include_min_extension
      "#{output_path}#{File.extname(original_path)}"
    end

  end

end