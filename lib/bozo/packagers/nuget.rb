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
      @libraries << NugetLibraryPackage.new(project)
    end

    def executable(project)
      @executables << NugetExecutablePackage.new(project)
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
      @libraries.each {|project| package project}
      @executables.each {|project| package project}
    end

    private

    def package(project)
      dependencies = project.dependencies
      files = project.files
      spec_path = generate_specification(project.name, dependencies, files)
      create_package(project.name, spec_path, true)
    end
    
    def generate_specification(project, dependencies, files)
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
            doc.dependencies do
              dependencies.each do |dep|
                doc.dependency(dep)
              end
            end
          end
          doc.files do
            files.each do |file|
              doc.file(file)
            end
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

  private

  class NugetExecutablePackage

    def initialize(project)
      @name = project
    end

    def name
      @name
    end

    def dependencies
      []
    end

    def files
      files = []
      files << {:src => File.expand_path(File.join('temp', 'msbuild', @name, '**', '*.*')).gsub(/\//, '\\'), :target => 'exe'}
      files
    end

  end

  class NugetLibraryPackage

    def initialize(project)
      @name = project
    end

    def name
      @name
    end

    def dependencies
      project_reference_dependencies + nuget_dependencies
    end

    def files
      files = []
      files << { :src => File.expand_path(File.join('temp', 'msbuild', @name, '**', "#{@name}.dll")).gsub(/\//, '\\'), :target => 'lib' }
      files
    end

    private

    def project_reference_dependencies
      doc = Nokogiri::XML(File.open(project_file))

      dependencies = []
      doc.xpath('//proj:Project/proj:ItemGroup/proj:ProjectReference/proj:Name', {"proj" => "http://schemas.microsoft.com/developer/msbuild/2003"}).each do |node|
        dependencies << {:id => node.text}
      end
      
      dependencies
    end

    # get dependencies from packages.config
    def nuget_dependencies
      package_file = packages_file
      return [] unless File.exist? package_file

      doc = Nokogiri::XML(File.open(package_file))

      dependencies = []
      doc.xpath('//packages/package').each do |node|
        dependencies << {:id => node[:id], :version => node[:version]}
      end

      dependencies
    end

    def packages_file
      # TODO: need to include the '**' to search through all directories
      File.expand_path(File.join('src', 'csharp', @name, 'packages.config'))
    end

    def project_file
      File.expand_path(File.join('src', 'csharp', @name, "#{@name}.csproj"))
    end

  end
  
end