module Bozo::Hooks

  class FxCop

    def fxcop_dir
      File.join(ENV['ProgramFiles(x86)'], 'Microsoft Fxcop 10.0', 'fxcopcmd.exe')
    end

    def post_compile
      out_path = File.expand_path File.join('temp', 'fxcop')
      FileUtils.mkdir_p out_path

      framework_versions = [:net35, :net40]

      framework_versions.each do |framework_version|
        args = []
        args << '"' + fxcop_dir + '"'
        args << "/out:#{out_path}\\FxCop-#{framework_version}-Results.xml"

        project_dirs.each do |project|
          projects = project_files(project, framework_version)

          projects.each do |project_file|
            puts project_file

            project_path = File.expand_path(project_file).gsub(/\//, '\\')
            args << "/file:\"#{project_path}\""
          end
        end

        Bozo.execute_command :fx_cop, args
      end
    end

    def required_tools
      :fx_cop
    end

    def project_files(project_path, framework_version)
      project_name = File.basename(project_path)
      # TODO: add support for .exe
      project_file_matcher = File.expand_path File.join(project_path, framework_version.to_s, "#{project_name}.dll")
      Dir[project_file_matcher]
    end

    def project_dirs()
      project_file_matcher = File.expand_path File.join('temp', 'msbuild', '*')
      Dir[project_file_matcher]
    end

  end

end