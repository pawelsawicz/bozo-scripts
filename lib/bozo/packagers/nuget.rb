require 'nokogiri'

module Bozo::Packagers

  class Nuget
    
    def initialize
      @libraries = []
      @executables = []
    end
    
    def destination(destination)
      @destination = destination
    end
    
    def library(project)
      @libraries << project
    end

    def executable(project)
      @executables << project
    end
    
    def required_tools
      :nuget
    end

    def project_url(url)
      @project_url = url
    end

    def license_url(url)
      @license_url = url
    end

    def author(author)
      @author = author
    end
    
    def to_s
      "Publish projects with nuget #{@libraries | @executables} to #{@destination}"
    end
    
    def execute
      @libraries.each {|project| package_library project}
      @executables.each {|project| package_executable project}
    end

    private
    
    def package_library(project)
      spec_path = generate_specification(project) do |doc|
        doc.file(:src => File.expand_path(File.join('temp', 'msbuild', project, '**', '*.*')).gsub(/\//, '\\'), :target => 'lib')
      end
      create_package(project, spec_path)
    end

    def package_executable(project)
      spec_path = generate_specification(project) do |doc|
        doc.file(:src => File.expand_path(File.join('temp', 'msbuild', project, '**', '*.*')).gsub(/\//, '\\'), :target => 'exe')
      end
      create_package(project, spec_path, true)
    end
    
    def generate_specification(project)
      log_debug "Generating specification for #{project}"
      builder = Nokogiri::XML::Builder.new do |doc|
        doc.package(:xmlns => "http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd") do
          doc.metadata do
            doc.id project
            doc.version_ package_version
            doc.authors @author
            doc.description project
            doc.projectUrl @project_url
            doc.licenseUrl @license_url
          end
          doc.files do
            yield doc            
          end
        end
      end
      spec_path = File.expand_path(File.join('temp', 'nuget', "#{project}.nuspec"))
      FileUtils.mkdir_p File.dirname(spec_path)
      File.open(spec_path, 'w+') {|f| f.write(builder.to_xml)}
      spec_path
    end

    # Returns the version that the package should be given.
    def package_version
      # If running on a build server then it is a real release, otherwise it is
      # a preview release and the version should reflect that.
      if build_server?
        version
      else
        "#{version}-pre#{env['GIT_HASH']}"
      end
    end
    
    def create_package(project, spec_path, omit_analysis = false)
      args = []
      
      dist_dir = File.expand_path(File.join('dist', 'nuget'))
      
      args << File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
      args << 'pack'
      args << "\"#{spec_path}\""
      args << '-OutputDirectory'
      args << "\"#{dist_dir}\""
      args << '-NoPackageAnalysis' if omit_analysis
      
      # Ensure the directory is there because Nuget won't make it
      FileUtils.mkdir_p dist_dir
      
      log_debug "Creating nuget package for #{project}"
      
      execute_command :nuget, args
    end
    
  end
  
end