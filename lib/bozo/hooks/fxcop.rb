module Bozo::Hooks

  class FxCop

    @@defaults = {
      :types => [],
      :framework_versions => [:net35, :net40],
      :project => nil
    }

    def config_with_defaults
      @@defaults.merge @config
    end

    def initialize
      @config = {}
    end

    def type(type)
      @config[:types] = [] if @config[:types] == nil
      @config[:types] << type
    end

    def project(project)
      @config[:project] = project
    end

    def path
      File.join(ENV['ProgramFiles(x86)'], 'Microsoft Fxcop 10.0', 'fxcopcmd.exe')
    end

    def configuration
      config_with_defaults
    end

    def output_path
      out_path = File.expand_path File.join('temp', 'fxcop')
      FileUtils.mkdir_p out_path
      out_path
    end

    def post_compile
      config = configuration

      if config[:project] == nil
        execute_projects config
      else
        execute_fxcop_project config
      end
    end

    def execute_projects(config)
      config[:framework_versions].each do |framework_version|
        args = []
        args << '"' + path + '"'
        args << "/out:#{output_path}\\FxCop-#{framework_version}-Results.xml"
        args << "/types:" + config[:types].join(',') if config[:types].length > 0

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

    def execute_fxcop_project(config)
      args = []
      args << '"' + path + '"'
      args << "/out:\"#{output_path}\\FxCop-#{File.basename(config[:project], '.*')}-Results.xml\""
      args << "/project:\"#{config[:project]}\""
      args << "/types:" + config[:types].join(',') if config[:types].length > 0

      Bozo.execute_command :fx_cop, args
    end

    def project_files(project_path, framework_version)
      project_name = File.basename(project_path)
      file_matcher = File.expand_path File.join(project_path, framework_version.to_s, "#{project_name}.{dll,exe}")
      Dir[file_matcher]
    end

    def project_dirs()
      project_file_matcher = File.expand_path File.join('temp', 'msbuild', '*')
      Dir[project_file_matcher]
    end

    def required_tools
      :fx_cop
    end

  end

end