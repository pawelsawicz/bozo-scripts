require 'nokogiri'

module Bozo::Packagers

  class Nuget

    def initialize
      @libraries = []
      @executables = []
      @websites = []
      @resources = []
    end

    def destination(destination)
      @destination = destination
    end

    def library(project, *extfiles)
      @libraries << LibraryPackage.new(project, extfiles, self)
    end

    def library_with_option(project, opts = {})
      @libraries << LibraryPackage.new(project, opts[:extfiles], self, opts[:excluded_references])
    end

    def executable(project)
      @executables << ExecutablePackage.new(project)
    end

    def resource(project, base_directory)
      @resources << ResourcePackage.new(project, base_directory)
    end

    def website(project)
      @websites << WebsitePackage.new(project)
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
      "Publish projects with nuget #{@libraries | @executables | @websites} to #{@destination}"
    end

    def execute
      @libraries.each {|project| package project}
      @executables.each {|project| package project}
      @websites.each {|project| package project}
      @resources.each {|project| package project}
    end

    # Returns the version that the package should be given.
    def package_version
      env['BUILD_VERSION_FULL']
    end

    private

    def package(project)
      spec_path = generate_specification(project)
      create_package(project.name, spec_path, true)
    end

    def generate_specification(project)
      log_debug "Generating specification for #{project.name}"
      builder = Nokogiri::XML::Builder.new do |doc|
        doc.package(:xmlns => "http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd") do
          doc.metadata do
            doc.id project.name
            doc.version_ package_version
            doc.authors @author
            doc.description project.name
            doc.projectUrl @project_url
            doc.licenseUrl @license_url
            doc.dependencies do
              project.dependencies.each do |dep|
                doc.dependency(dep)
              end
            end
          end
          doc.files do
            project.files.each do |file|
              doc.file(file)
            end
          end
        end
      end
      spec_path = File.expand_path(File.join('temp', 'nuget', "#{project.name}.nuspec"))
      FileUtils.mkdir_p File.dirname(spec_path)
      File.open(spec_path, 'w+') {|f| f.write(builder.to_xml)}
      spec_path
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

  class ResourcePackage
    def initialize(project, base_directory)
      @name = project
      @base_directory = base_directory
    end

    def name
      @name
    end

    def dependencies
      []
    end

    def files
      [{:src => File.expand_path(File.join(@base_directory, '**', '*.*')).gsub(/\//, '\\')}]
    end
  end

  class ExecutablePackage
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
      [{:src => File.expand_path(File.join('temp', 'msbuild', @name, '**', '*.*')).gsub(/\//, '\\')}]
    end
  end

  class LibraryPackage

    def initialize(project, extfiles, nuget, excluded_references = [])
      @name = project
      @nuget = nuget
      @extfiles = extfiles
      @excluded_references = excluded_references
    end

    def name
      @name
    end

    def dependencies
      project_reference_dependencies + nuget_dependencies
    end

    def files
      files = []

      %w{dll pdb xml}.map do |extension|
        files << {:src => File.expand_path(File.join('temp', 'msbuild', @name, '**', "#{@name}.#{extension}")).gsub(/\//, '\\'), :target => 'lib'}
      end

      @extfiles.map do |file|
        files << {:src => File.expand_path(File.join('temp', 'msbuild', @name, '**', file)).gsub(/\//, '\\'), :target => 'lib'}
      end

      files
    end

    private

    def project_reference_dependencies
      doc = Nokogiri::XML(File.open(project_file))

      doc.xpath('//proj:Project/proj:ItemGroup/proj:ProjectReference/proj:Name', {"proj" => "http://schemas.microsoft.com/developer/msbuild/2003"}).map do |node|
        {:id => node.text, :version => "[#{@nuget.package_version}]"}
      end
    end

    # get dependencies from packages.config
    def nuget_dependencies
      package_file = packages_file
      return [] unless File.exist? package_file

      doc = Nokogiri::XML(File.open(package_file))

      doc.xpath('//packages/package').map do |node|
        {:id => node[:id], :version => "[#{node[:version]}]"} unless @excluded_references.include? node[:id]
      end
    end

    def packages_file
      find_file_in_project 'packages.config'
    end

    def project_file
      find_file_in_project "#{@name}.csproj"
    end

    def find_file_in_project(file_name)
      file = File.expand_path(File.join('src', 'csharp', @name, file_name))
      file = File.expand_path(File.join('test', 'csharp', @name, file_name)) unless File.exist? file
      file
    end

  end

  class WebsitePackage

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
      [{:src => File.expand_path(File.join('temp', 'msbuild', @name, '**', '*.*')).gsub(/\//, '\\')}]
    end

  end

end
