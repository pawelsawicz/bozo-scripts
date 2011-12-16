require 'nokogiri'

module Bozo::Publishers

  class Nuget
    
    def initialize
      @projects = []
    end
    
    def destination(destination)
      @destination = destination
    end
    
    def project(project)
      @projects << project
    end
    
    def required_tools
      :nuget
    end
    
    def to_s
      "Publish projects with nuget #{@projects} to #{@destination}"
    end
    
    def execute
      @projects.each {|project| package_project(project)}
    end
    
    def package_project(project)
      spec_path = generate_specification(project)
      create_package(project, spec_path)
    end
    
    def generate_specification(project)
      Bozo.log_debug "Generating specification for #{project}"
      builder = Nokogiri::XML::Builder.new do |doc|
        doc.package(:xmlns => "http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd") do
          doc.metadata do
            doc.id project
            doc.version_ "#{Bozo::Configuration.version}-#{ENV['BOZO_GIT_HASH']}" # Need to know if a 'proper' build and then not add hash
            doc.authors 'Zopa'
            doc.description project
            doc.projectUrl 'http://www.zopa.com'
            doc.licenseUrl 'http://www.zopa.com'
          end
          doc.files do
            doc.file(:src => File.expand_path(File.join('temp', 'msbuild', project, '**', '*.dll')).gsub(/\//, '\\'), :target => 'lib')
            doc.file(:src => File.expand_path(File.join('temp', 'msbuild', project, '**', '*.pdb')).gsub(/\//, '\\'), :target => 'lib')
          end
        end
      end
      spec_path = File.expand_path(File.join('temp', 'nuget', "#{project}.nuspec"))
      FileUtils.mkdir_p File.dirname(spec_path)
      File.open(spec_path, 'w+') {|f| f.write(builder.to_xml)}
      spec_path
    end
    
    def create_package(project, spec_path)
      args = []
      
      dist_dir = File.expand_path(File.join('dist', 'nuget'))
      
      args << File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
      args << 'pack'
      args << "\"#{spec_path}\""
      args << '-OutputDirectory'
      args << "\"#{dist_dir}\""
      
      # Ensure the directory is there because Nuget won't make it
      FileUtils.mkdir_p dist_dir
      
      Bozo.log_debug "Creating nuget package for #{project}"
      
      Bozo.execute_command :nuget, args
    end
    
  end
  
end