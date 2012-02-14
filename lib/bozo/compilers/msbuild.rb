require 'nokogiri'

module Bozo::Compilers

  class Msbuild
  
    @@defaults = {
      :version => 'v4.0.30319',
      :framework => 'Framework64',
      :properties => {:configuration => :release},
      :targets => [:clean, :build],
      :max_cores => nil
    }
    
    def config_with_defaults
      @@defaults.merge @config
    end
  
    def initialize
      @config = {}
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

    # Assign how many cores should be used by msbuild
    #
    # @param [Integer] cores
    #     The maximum number of cores to allow msbuild to use
    def max_cores(cores)
      @config[:max_cores] = cores
    end
    
    alias :properties :property
    
    def target(target)
      @config[:targets] ||= []
      @config[:targets] << target
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
      projects = project_files('src') | project_files('test')
      
      projects.each do |project_file|          
        project_name = File.basename(project_file).gsub(/\.csproj$/, '')
        
        log_debug project_name
        
        args = []
        config = configuration
        
        framework_version = 'unknown'
        
        File.open(project_file) do |f|        
          framework_version = Nokogiri::XML(f).css('Project PropertyGroup TargetFrameworkVersion').first.content
          framework_version = framework_version.sub('v', 'net').sub('.', '')
        end
        
        config[:properties][:outputpath] = File.expand_path(File.join('temp', 'msbuild', project_name, framework_version))
        config[:properties][:solutiondir] = File.expand_path('.') + '/'

        args << File.join(ENV['WINDIR'], 'Microsoft.NET', config[:framework], config[:version], 'msbuild.exe')
        args << '/nologo'
        args << '/verbosity:normal'
        args << "/target:#{config[:targets].map{|t| t.to_s}.join(';')}"
        args << "/maxcpucount" if config[:max_cores].nil? # let msbuild decide how many cores to use
        args << "/maxcpucount:#{config[:max_cores]}" unless config[:max_cores].nil? # specifying the number of cores
        
        config[:properties].each do |key, value|
          args << "/property:#{key}=\"#{value}\""
        end
        
        args << "\"#{project_file}\""
        
        execute_command :msbuild, args
      end
    end
    
    def project_files(directory)
      project_file_matcher = File.expand_path(File.join(directory, 'csharp', '**', '*.csproj'))
      Dir[project_file_matcher]
    end
    
    def required_tools
      :stylecop unless @config[:without_stylecop]
    end
    
  end
  
end