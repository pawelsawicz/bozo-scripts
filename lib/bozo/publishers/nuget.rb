require 'fileutils'

module Bozo::Publishers

  # Publisher that pushes package to nuget
  class Nuget

    def initialize
      @packages = []
    end

    def server(server)
      @server = server
    end

    def api_key(api_key)
      @api_key = api_key
    end

    def package(package)
      @packages << package
    end

    def execute
      raise Bozo::ConfigurationError.new 'You must specify a nuget server address' if @server.empty?

      if @packages.empty?
        Dir[File.join('dist', 'nuget', '**', '*')].each do |source_file|
          push File.expand_path(source_file)
        end
      else
        @packages.each do |package|
          Dir[File.join('dist', 'nuget', '**', "#{@package}*")].each do |source_file|
            push File.expand_path(source_file)
          end
        end
      end
    end

    private

    def push(source_file)
      args = []
      args << File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
      args << "push"
      args << "\"#{source_file}\""
      args << "-s #{@server}"

      if !@api_key.nil?
        args << "\"#{@api_key}\""
      end
      execute_command :nuget, args
    end
  end

end