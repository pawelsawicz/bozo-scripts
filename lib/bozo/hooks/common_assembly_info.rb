module Bozo::Hooks

  class CommonAssemblyInfo
    
    def pre_compile
      Bozo.log_info 'Generating common assembly info'
      
      version = Bozo::Configuration.version
      trademark = Bozo::ENV['GIT_HASH_FULL']

      Bozo.log_debug version
      Bozo.log_debug trademark
    end
    
  end

end