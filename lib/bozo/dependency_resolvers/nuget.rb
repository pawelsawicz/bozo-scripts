module Bozo::DependencyResolvers

  # Class for resolving project dependencies using NuGet.
  class Nuget
    
    # Creates a new instance.
    def initialize
      @sources = []
      @packages_to_update = []
    end

    # Add a URL that should be within the machine's configuration for
    # package resolution URLs.
    #
    # @param [String] url
    #     A NuGet package resolving URL.
    def source(url)
      @sources << url
    end

    def packages_to_update(packages)
      @packages_to_update.push *packages
    end

    # Returns the build tools required for this dependency resolver to run
    # successfully.
    def required_tools
      :nuget
    end
    
    # Ensure all the specified sources are present and execute the dependency
    # resolver for all the files matching <tt>test/**/packages.config</tt> and
    # <tt>src/**/packages.config</tt> and <tt>packages.config</tt> if present.
    def execute
      add_package_sources
      install_packages 'test', '**', 'packages.config'
      install_packages 'src', '**', 'packages.config'
      install_packages 'packages.config'

      update_internal_packages 'test', '**', 'packages.config'
      update_internal_packages 'src', '**', 'packages.config'
      update_internal_packages 'packages.config'
    end

    private

    # Adds any sources that are required but are not mentioned by the
    # <tt>NuGet sources List</tt> command.
    def add_package_sources
      existing = `#{nuget_path} sources List` if @sources.any?

      @sources.select {|source| not existing.upcase.include? source.upcase}.each do |source|
        quoted_source = "\"#{source}\""
        log_debug "Missing nuget package source #{quoted_source}"

        args = []

        args << nuget_path
        args << 'sources'
        args << 'Add'
        args << '-Name'
        args << quoted_source
        args << '-Source'
        args << quoted_source

        log_debug "Adding nuget package source #{quoted_source}"

        execute_command :nuget, args
      end
    end
    
    def install_packages(*args)
      path_matcher = File.expand_path(File.join(args))          
      Dir[path_matcher].each do |path|
        args = []
      
        args << nuget_path
        args << 'install'            
        args << "\"#{path}\""
        args << '-OutputDirectory'
        args << "\"#{File.expand_path(File.join('packages'))}\""
        
        log_debug "Resolving nuget dependencies for #{path}"
        
        execute_command :nuget, args
      end
    end

    def update_internal_packages(*args)
      path_matcher = File.expand_path(File.join(args))
      Dir[path_matcher].reject { |filename| filename.include? "/obj/" }.each do |path|
        
        # if none of the specified packages are found in the current packages.config, do nothing
        packages_found_in_path = [];

        @packages_to_update.each do |package|
          # make sure the packages.config file contains an entry for each package.
          # Nuget will fail if you try to update a package not present in the packages.config
          file_contents = File.read(path)
          if file_contents.include? "\"#{package}\""
            log_debug "Found #{package} in #{path}"
            packages_found_in_path << "#{package}"
          else
            log_debug "Did NOT find #{package} in #{path}"
          end
        end

        if !packages_found_in_path.empty?
          args = []
          args << nuget_path
          args << 'update'
          args << "\"#{path}\""

          args << '-Id'
          packages_found_in_path.each do |package|
            args << "\"#{package}\""
          end
          args << '-RepositoryPath'
          args << "\"#{File.expand_path(File.join('packages'))}\""

          log_debug "Updating internal packages in #{path}"

          execute_command :nuget, args
        end
      end
    end
    
    def nuget_path
      File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
    end
 
  end
  
end