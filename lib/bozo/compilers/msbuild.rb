require 'nokogiri'
require 'fileutils'

module Bozo::Compilers

  class Msbuild

    def config_with_defaults
      defaults = {
        :version => 'v4.0.30319',
        :framework => 'Framework64',
        :properties => {:configuration => :release},
        :max_cores => nil
      }

      default_targets = [:build]

      config = defaults.merge @config
      config[:targets] = (@targets or default_targets).clone
      config[:websites_as_zip] ||= false
      config
    end

    def initialize
      @config = {}
      @exclude_projects = []
    end

    def version(version)
      @config[:version] = version
    end

    def framework(framework)
      @config[:framework] = framework
    end

    def solution(path)
      @config[:solution] = path
    end

    def property(args)
      @config[:properties] ||= {}
      @config[:properties] = @config[:properties].merge(args)
    end

    def exclude_project(project_name)
      @exclude_projects << project_name
    end

    def websites_as_zip
      @config[:websites_as_zip] = true
    end

    # Assign how many cores should be used by msbuild
    #
    # @param [Integer] cores
    #     The maximum number of cores to allow msbuild to use
    def max_cores(cores)
      @config[:max_cores] = cores
    end

    alias :properties :property

    def target(target)
      @targets ||= []
      @targets << target
    end

    def to_s
      config = configuration
      "Compile with msbuild #{config[:version]} building #{config[:solution]} with properties #{config[:properties]} for targets #{config[:targets]}"
    end

    def without_stylecop
      @config[:without_stylecop] = true
    end

    def configuration
      config_with_defaults
    end

    def execute
      projects = (project_files('test') | project_files('src')).map { |file| create_project file }
      
      # Clean all the projects first.
      projects.each do |project|
        project.clean configuration
      end

      # Build all the projects so they can utilize each others artifacts.
      projects.each do |project|
        project.build configuration
      end
    end

    def project_files(directory)
      project_file_matcher = File.expand_path(File.join(directory, 'csharp', '**', '*.csproj'))
      Dir[project_file_matcher].select { |p| not @exclude_projects.include?(File.basename p, '.csproj') }
    end

    private

    # Creates a project based on the project_file type.
    # Defaults to a class library project if it cannot be determined.
    # @return [Project]
    def create_project(project_file)
      project_name = File.basename(project_file).gsub(/\.csproj$/, '')
      log_debug project_name

      project_class_for(project_file).new project_file, project_name
    end

    # @return [Class]
    def project_class_for(project_file)
      project_types = project_types_from project_file
      web_app_type = '{349c5851-65df-11da-9384-00065b846f21}'
      if tools_version(project_file) == "3.5"
        project_types.include?(web_app_type) ? WebProject2008 : ClassLibrary
      else
        project_types.include?(web_app_type) ? WebProject2010 : ClassLibrary
      end
    end

    # @return [Array]
    def project_types_from(project_file)
      project_types = []

      File.open(project_file) do |f|
        element = Nokogiri::XML(f).css('Project PropertyGroup ProjectTypeGuids').first
        project_types = element.content.split(';').map {|e| e.downcase } unless element.nil?
      end

      project_types
    end

    def tools_version(project_file)
      tools_version = nil

      File.open(project_file) do |f|
        element = Nokogiri::XML(f).css('Project').first
        tools_version = element['ToolsVersion'] unless element.nil?
      end

      tools_version
    end

  end

  private

  class Project

    include Bozo::Runner

    def initialize(project_file, project_name)
      @project_file = project_file
      @project_name = project_name
    end

    def build(configuration)
      populate_config(configuration)
      args = generate_args configuration
      execute_command :msbuild, args
    end

    def clean(configuration)
      config = configuration.dup
      config.delete(:max_cores)
      config[:targets] = [:clean]
      args = generate_args config
      execute_command :msbuild, args

      remove_obj_directory
    end

    def framework_version
      framework_version = 'unknown'

      File.open(@project_file) do |f|
        framework_version = Nokogiri::XML(f).css('Project PropertyGroup TargetFrameworkVersion').first.content
        framework_version = framework_version.sub('v', 'net').sub('.', '')
      end

      framework_version
    end

    def generate_args(config)
      args = []

      args << File.join(ENV['WINDIR'], 'Microsoft.NET', config[:framework], config[:version], 'msbuild.exe')
      args << '/nologo'
      args << '/verbosity:normal'
      args << '/nodeReuse:false'
      args << "/target:#{config[:targets].map{|t| t.to_s}.join(';')}"
      args << "/p:StyleCopEnabled=false" if config[:without_stylecop]
      args << "/maxcpucount" if config[:max_cores].nil? # let msbuild decide how many cores to use
      args << "/maxcpucount:#{config[:max_cores]}" unless config[:max_cores].nil? # specifying the number of cores

      config[:properties].each do |key, value|
        args << "/property:#{key}=\"#{value}\""
      end

      args << "\"#{@project_file}\""
    end

    def windowsize_path(path)
      path.gsub(/\//, '\\')
    end

    def temp_project_path
      File.expand_path(File.join('temp', 'msbuild', @project_name))
    end

    def location
      File.expand_path(File.join(temp_project_path, framework_version))
    end

    private

    def remove_obj_directory
      if Dir.exists?(obj_directory)
        log_info "Removing #{obj_directory}"
        FileUtils.rm_rf obj_directory
      end
    end

    def obj_directory
      File.join(project_path, 'obj')
    end

    def project_path
      File.dirname(@project_file)
    end

  end

  class ClassLibrary < Project

    def populate_config(config)
      config[:properties][:outputpath] = location + '/'
      config[:properties][:solutiondir] = windowsize_path(File.expand_path('.') + '//')
    end

  end

  class WebProject2010 < Project

    def populate_config(config)
      config[:targets] << :package

      if config[:websites_as_zip]
        config[:properties][:packagelocation] = location + '/Site.zip'
        config[:properties][:packageassinglefile] = true
      else
        config[:properties][:_packagetempdir] = temp_project_path
      end

      config[:properties][:solutiondir] = windowsize_path(File.expand_path('.') + '//')
    end

  end

  class WebProject2008 < Project

    require 'zip/zip'

    def build(configuration)
      super

      zip_website if configuration[:websites_as_zip]
    end

    def zip_website
      zip_file = zip_location_dir 'Site.zip'

      Dir["#{location}/**/**"].reject { |f| f == zip_file }.each do |file|
        FileUtils.rm_rf file
      end
    end

    def zip_location_dir(zip_file_name)
      zip_path = location + "/#{zip_file_name}"

      Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zipfile|
        Dir["#{location}/**/**"].each do |file|
          zipfile.add(file.sub(location + '/', ''), file)
        end
      end

      zip_path
    end

    def populate_config(config)
      config[:targets] << :'ResolveReferences'
      config[:targets] << :'_CopyWebApplication'

      config[:properties][:OutDir] = location + '/bin/'
      config[:properties][:WebProjectOutputDir] = windowsize_path location
      config[:properties][:_DebugSymbolsProduced] = false

      config[:properties][:solutiondir] = windowsize_path(File.expand_path('.') + '//')
    end

  end

end
