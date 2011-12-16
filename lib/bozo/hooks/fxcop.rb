module Bozo::Hooks

  class FxCop

    def post_compile
      out_path = File.expand_path(File.join('temp', 'fxcop'))
      FileUtils.mkdir_p out_path
      args = []

      args << '"' + File.join(ENV['ProgramFiles(x86)'], 'Microsoft Fxcop 10.0', 'fxcopcmd.exe') + '"'

      projects = project_files('src') | project_files('test')

      projects.each do |project_file|
        project_name = File.basename(project_file).gsub(/\.csproj$/, '')
        project_path = File.expand_path(File.join('temp', 'msbuild', project_name, 'net35', project_name)).gsub(/\//, '\\')
        args << "/file:\"#{project_path}.dll\""
      end

      args << "/out:#{out_path}\\FxCopResults.xml"

      Bozo.execute_command :fx_cop, args
    end

    def required_tools
      :fx_cop
    end

    def project_files(directory)
      project_file_matcher = File.expand_path(File.join(directory, 'csharp', '**', '*.csproj'))
      Dir[project_file_matcher]
    end

  end

end