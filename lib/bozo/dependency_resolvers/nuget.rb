module Bozo::DependencyResolvers

  # Class for resolving project dependencies using NuGet.
  class Nuget
    
    # Creates a new instance.
    def initialize
      @sources = []
    end

    # Add a URL that should be within the machine's configuration for
    # package resolution URLs.
    #
    # @param [String] url
    #     A NuGet package resolving URL.
    def source(url)
      @sources << url
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
    
    def nuget_path
      File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
    end
 
  end
  
end