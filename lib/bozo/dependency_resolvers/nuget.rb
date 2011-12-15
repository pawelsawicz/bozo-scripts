module Bozo::DependencyResolvers

  class Nuget
    
    def required_tools
      :nuget
    end
    
    def execute
      install_packages 'src', '**', 'packages.config'
      install_packages 'test', '**', 'packages.config'
    end
    
    def install_packages(*args)
      path_matcher = File.expand_path(File.join(args))          
      Dir[path_matcher].each do |path|
        args = []
      
        args << File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
        args << 'install'            
        args << "\"#{path}\""
        args << '-OutputDirectory'
        args << "\"#{File.expand_path(File.join('packages'))}\""
        
        Bozo.log_debug "Resolving nuget dependencies for #{path}"
        
        Bozo.execute_command :nuget, args
      end
    end
    
  end
  
end