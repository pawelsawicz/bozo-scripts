module Bozo::Hooks

  class CommonAssemblyInfo
    
    def pre_compile
      Bozo.log_info 'Generating common assembly info'
      
      version = Bozo::Configuration.version
      git_hash = Bozo::ENV['GIT_HASH_FULL']
      computer_name = ENV['COMPUTERNAME']
      trademark = computer_name ? "#{computer_name} #{git_hash}" : git_hash
      path = File.expand_path(File.join('build', 'CommonAssemblyInfo.cs'))
      
      Bozo.log_debug "Version: #{version}"
      Bozo.log_debug "Commit hash: #{git_hash}"
      Bozo.log_debug "Computer name: #{computer_name}" if computer_name
      Bozo.log_debug "Path: #{path}"
      
      File.open(path, 'w+') do |f|
        f << "using System.Reflection;\n"
        f << "\n"
        f << "[assembly: AssemblyCompany(\"Zopa\")]\n"
        f << "[assembly: AssemblyVersion(\"#{version}\")]\n"
        f << "[assembly: AssemblyFileVersion(\"#{version}\")]\n"
        f << "[assembly: AssemblyTrademark(\"#{trademark}\")]"
      end
    end
    
  end

end