require 'fileutils'

module Bozo::Publishers

  # Publisher that pushes package to nuget
  class Nuget

    def server(server)
      @server = server
    end

    def api_key(api_key)
      @api_key = api_key
    end

    def execute
      raise Bozo::ConfigurationError.new 'You must specify a nuget server address' if @server.empty?
      raise Bozo::ConfigurationError.new 'You must specify a nuget api key' if @api_key.empty?

      Dir[File.join('dist', 'nuget', '**', '*')].each do |source_file|
        push File.expand_path(source_file)
      end
    end

    private

    def push(source_file)
      args = []
      args << File.expand_path(File.join('build', 'tools', 'nuget', 'NuGet.exe'))
      args << "push"
      args << "\"#{source_file}\""
      args << "\"#{@api_key}\""
      args << "-s #{@server}"
      execute_command :nuget, args
    end

  end

end