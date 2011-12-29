module Bozo::Hooks

  class CommonAssemblyInfo
    
    def pre_compile
      log_info 'Generating common assembly info'
      
      version = Bozo::Configuration.version
      git_hash = env['GIT_HASH_FULL']
      computer_name = env['COMPUTERNAME']
      trademark = computer_name ? "#{computer_name} #{git_hash}" : git_hash
      path = File.expand_path(File.join('build', 'CommonAssemblyInfo.cs'))
      
      log_debug "Version: #{version}"
      log_debug "Commit hash: #{git_hash}"
      log_debug "Computer name: #{computer_name}" if computer_name
      log_debug "Path: #{path}"
      
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