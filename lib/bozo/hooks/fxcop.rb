module Bozo::Hooks

  # Specifies a hook for running FxCop.
  #
  # The default configuration runs against the compiled assemblies produced via
  # msbuild.
  #
  # Alternatively a specific .fxcop project file can be specified in the 
  # configuration.
  class FxCop

    def self.default_path
      if ENV['ProgramFiles(x86)'].nil?
        program_files_path = ENV['ProgramFiles']
      else
        program_files_path = ENV['ProgramFiles(x86)']
      end

      File.join(program_files_path, 'Microsoft Fxcop 10.0', 'fxcopcmd.exe') unless program_files_path.nil?
    end

    def initialize
      @@defaults = {
        :types => [],
        :framework_versions => [:net35, :net40],
        :project => nil,
        :path => FxCop.default_path
      }

      @config = {}
    end

    # Adds a type to analyze
    def type(type)
      @config[:types] ||= []
      @config[:types] << type
    end

    # Specifies an fxcop project file
    def project(project)
      @config[:project] = project
    end

    # Specifies the fxcop path
    def path(path)
      @config[:path] = path
    end

    # Runs the post_compile hook
    def post_compile
      config = configuration

      if config[:project].nil?
        execute_projects config
      else
        execute_fxcop_project config
      end
    end

    private

    def configuration
      config_with_defaults
    end

    def config_with_defaults
      @@defaults.merge @config
    end

    # The path to output the fxcop results to
    def output_path
      out_path = File.expand_path File.join('temp', 'fxcop')
      FileUtils.mkdir_p out_path
      out_path
    end

    # Executes fxcop against the msbuild built assemblies
    #
    # @param [Hash] config
    #     The fxcop configuration
    def execute_projects(config)
      Bozo.log_debug "Executing projects with '#{config[:path]}'" if config[:framework_versions].any?

      config[:framework_versions].each do |framework_version|
        args = []
        args << '"' + config[:path] + '"'
        args << "/out:#{output_path}\\FxCop-#{framework_version}-Results.xml"
        args << "/types:" + config[:types].join(',') unless config[:types].empty?

        project_dirs.each do |project|
          projects = project_files(project, framework_version)

          projects.each do |project_file|
            project_path = File.expand_path(project_file).gsub(/\//, '\\')
            args << "/file:\"#{project_path}\""
          end
        end

        Bozo.execute_command :fx_cop, args
      end
    end

    # Executes a .fxcop file
    #
    # @param [Hash] config
    #     The fxcop configuration
    def execute_fxcop_project(config)
      Bozo.log_debug "Executing fxcop project '#{config[:project]}' with '#{config[:path]}'"

      args = []
      args << '"' + config[:path] + '"'
      args << "/out:\"#{output_path}\\FxCop-#{File.basename(config[:project], '.*')}-Results.xml\""
      args << "/project:\"#{config[:project]}\""
      args << "/types:" + config[:types].join(',') unless config[:types].empty?

      Bozo.execute_command :fx_cop, args
    end

    # List of compiled assemblies and executables

    # @param [String] project_path
    #     The path of the project
    # @param [Symbol] framework_version
    #     The framework_version to find assemblies for
    def project_files(project_path, framework_version)
      project_name = File.basename(project_path)
      file_matcher = File.expand_path File.join(project_path, framework_version.to_s, "#{project_name}.{dll,exe}")
      Dir[file_matcher]
    end

    # List of all the msbuild built projects
    def project_dirs
      project_file_matcher = File.expand_path File.join('temp', 'msbuild', '*')
      Dir[project_file_matcher]
    end

  end

end