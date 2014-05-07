require 'fileutils'

module Bozo::Publishers

  # Publisher that pushes package to nuget
  class NugetPush

    def initialize
      @package_directories = []
    end

    def package_directories(*args)
      @package_directories << args
    end

    def server(server)
      @server = server
    end

    def api_key(api_key)
      @api_key = api_key
    end

    def execute
      raise Bozo::ConfigurationError.new 'You must specify at least one source file or directory' if @package_directories.empty?
      raise Bozo::ConfigurationError.new 'You must specify a nuget server address' if @server.empty?
      raise Bozo::ConfigurationError.new 'You must specify a nuget api key' if @api_key.empty?

      source_directories do |source_files|
        source_files.each do |source_file|
          push source_file
        end
      end
    end

    private

    def source_directories
      @package_directories.each do |dir|
        relative_source_dir = File.join(dir)
        source_dir = File.expand_path relative_source_dir
        source_dir_path = Pathname.new source_dir
        yield Dir[File.join(source_dir, '**', '*')]
      end
    end

    def push(source_file)
      log_debug "Publishing package \"#{source_file}\" to \"#{@server}\""
      `nuget push #{source_file} #{@api_key} -s #{@server}`
    end

  end

end