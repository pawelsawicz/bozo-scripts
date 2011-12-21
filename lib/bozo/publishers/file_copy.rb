require 'fileutils'

module Bozo::Publishers

  # Publisher that copies files from one location to another.
  class FileCopy

    # Creates a new instance.
    def initialize
      @directories = []
    end

    # Adds a source directory of files copy.
    #
    # Must be relative to the project root. All files within the directory and
    # its subdirectories will be copied to the destination directory,
    # maintaining the file structure.
    #
    # @params [Array] args
    #     Path to a directory relative to the project root.
    def directory(*args)
      @directories << args
    end

    # Set the destination directory of the file copy.
    #
    # Must be an absolute path.
    #
    # @params [String] destination
    #     The absolution path the source files should be copied to.
    def destination(destination)
      @destination = destination
    end

    def execute
      if @directories.empty? or @destination.nil?
        raise Bozo::ConfigurationError.new 'You must specify at least one source file or directory AND a destination directory'
      end

      ensure_no_clashing_files

      copy_pairs do |source, target|
        FileUtils.mkdir_p File.dirname(target)
        Bozo.log_debug "Publishing \"#{File.basename(source)}\" to \"#{target}\""
        FileUtils.cp source, target
      end
    end

    private

    # Checks the destination does not contain files that will be overwritten by
    # the source files.
    def ensure_no_clashing_files
      existing_files = []

      copy_pairs do |source, target|
        existing_files << target if File.exist? target
      end

      raise Bozo::ConfigurationError.new "Target files already exist - #{existing_files}" unless existing_files.empty?
    end

    def copy_pairs
      destination = File.join @destination

      @directories.each do |dir|
        relative_source_dir = File.join(dir)
        source_dir = File.expand_path relative_source_dir
        source_dir_path = Pathname.new source_dir

        Dir[File.join(source_dir, '**', '*')].each do |source_file|
          rel_path = Pathname.new(source_file).relative_path_from(source_dir_path).to_s
          target_file = File.join(destination, rel_path)
          yield source_file, target_file
        end
      end
    end

  end

end