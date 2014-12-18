module Bozo::Preparers

  class CommonAssemblyInfo

    def company_name(name)
      @company_name = name
    end

    def execute
      log_info 'Generating common assembly info'

      git_hash = env['GIT_HASH_FULL']
      computer_name = env['COMPUTERNAME']
      trademark = computer_name ? "#{computer_name} #{git_hash}" : git_hash
      path = File.expand_path(File.join('build', 'CommonAssemblyInfo.cs'))
      build_version = env['BUILD_VERSION']
      BUILD_VERSION_FULL = env['BUILD_VERSION_FULL']

      log_debug "Version: #{version}"
      log_debug "Information Version: #{build_version}"
      log_debug "Commit hash: #{git_hash}"
      log_debug "Computer name: #{computer_name}" if computer_name
      log_debug "Path: #{path}"

      File.open(path, 'w+') do |f|
        f << "using System.Reflection;\n"
        f << "\n"
        f << "[assembly: AssemblyCompany(\"#{@company_name}\")]\n"
        f << "[assembly: AssemblyVersion(\"#{build_version}\")]\n"
        f << "[assembly: AssemblyFileVersion(\"#{build_version}\")]\n"
        f << "[assembly: AssemblyInformationalVersion(\"#{BUILD_VERSION_FULL}\")]\n"
        f << "[assembly: AssemblyTrademark(\"#{trademark}\")]"
      end
    end

  end

end
