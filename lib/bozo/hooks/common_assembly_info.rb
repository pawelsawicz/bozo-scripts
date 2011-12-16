module Bozo::Hooks

  class CommonAssemblyInfo
    
    def pre_compile
      Bozo.log_info 'Common assembly info called'
      Bozo.log_debug `git log -1 --format="%h"`.strip
      Bozo.log_debug `git log -1 --format="%H"`.strip
    end
    
  end

end