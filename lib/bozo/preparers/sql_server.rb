module Bozo::Preparers

  # Executes a sql script
  #
  # == Hook configuration
  #
  #   prepare :sql_server do |t|
  #     t.variable 'DatabaseName', 'MyDatabase'
  #     t.variable 'MySecondVariable', 'HelloWorld'
  #     t.script 'my/specific/script.sql' # must be a specific file
  #     t.connection_string { |c| c[:config_value] } # a function taking the configuration as an argument
  #   end
  #
  # The variables are accessible via `$(KEY)` in the sql script.
  class SqlServer

    def execute
      configuration = load_config

      execute_command :sqlcmd, generate_args(configuration)
    end

    def variable(key, value)
      @variables ||= {}
      @variables[key] = value
    end

    def script(value)
      @script = value
    end

    def connection_string(&value)
      @connection_string = value
    end

    private

    def generate_args(configuration)
      connection_string = @connection_string.call(configuration)

      if connection_string.nil? || connection_string.length == 0
        raise Exception.new('No connection string specified')
      end

      args = []
      args << 'sqlcmd'
      args << "-S #{connection_string}"
      args << "-i #{@script}"
      @variables.each do |key, value|
        args << "-v #{key}=#{value}"
      end

      args
    end

    def load_config
      default_files = ['default.rb', "#{environment}.rb"]
      default_files << "#{env['MACHINENAME']}.rb" if env['MACHINENAME']

      configuration = Bozo::Configuration.new

      default_files.each do |file|
        path = File.join('config', file)
        configuration.load path if File.exist? path
      end

      configuration
    end

  end

end