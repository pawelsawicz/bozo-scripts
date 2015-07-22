require 'nokogiri'

module Bozo::TestRunners

  # Adds a code coverage test runner using openCover
  #
  # The default configuration looks for openCover in the ProgramFiles(x86) path
  #
  # Test runners can be defined foropenCover to run against. Each runner
  # produces a separate dotcover output
  class OpenCover
    def self.default_path
      File.join('build', 'tools', 'OpenCover', 'OpenCover.Console.exe')
    end

    def initialize
      @@defaults = {
        :path => OpenCover.default_path,
        :required => true
      }

      @config = {}
      @runners = []
    end

    # Returns whether opencover is installed at the configured path
    def opencover_installed?
      path = configuration[:path]

      return false if path.nil?

      File.exist? path
    end

    # Returns the build tools required for this dependency resolver to run
    # successfully.
    def required_tools
      :open_cover
    end

    # Adds a test runner
    #
    # @param [Symbol] runner
    #     A test runner to wrap with opencover
    def runner(runner, &block)
      add_instance runner, block
    end

    # Specifies whether covering with opencover is required
    #
    # If it is not required, and opencover cannot be found, then test runners
    # are executed without coverage. If opencover is required but cannot be
    # found then an error will occur.
    #
    # @param [boolean] required
    #     Whether opencover coverage is required
    def required?(required = nil)
      @config[:required] = required unless required.nil?
      
      @config[:required]
    end

    def execute
      if required? or opencover_installed?
        @runners.each {|runner| execute_with_coverage runner}
      else
        @runners.each {|runner| execute_without_coverage(runner)}
      end
    end

    private

    # Resolves the named class within the given namespace and then created an
    # instance of the class before adding it to the given collection and
    # yielding it to the configuration block when one is provided.
    #
    # @param [Symbol] type
    #     The name of the step executor.
    # @param [Proc] block
    #     Optional block to refine the configuration of the step executor.
    def add_instance(type, block)
      instance = Bozo::TestRunners.const_get(to_class_name(type)).new
      instance.extend Bozo::Runner
      @runners << instance
      block.call instance if block
    end

    # Converts a symbol into a Pascal Case class name.
    #
    # eg. `:single` => `"Single"`, `:two_words` => `"TwoWords"`.
    #
    # @param [Symbol] type
    #     The name of a step executor.
    def to_class_name(type)
      type.to_s.split('_').map{|word| word.capitalize}.join
    end

    def execute_without_coverage(runner)
      log_debug 'Running ' + runner.class.to_s + ' without coverage'
      runner.execute
    end

    def execute_with_coverage(runner)
      if required? & !opencover_installed?
        log_fatal "Attempting to run with coverage but opencover could not be found at #{configuration[:path]}"
      end

      log_debug "Running #{runner.class} with coverage"

      config = configuration
      opencover_path = config[:path]
      output_file = File.expand_path(File.join('temp', 'opencover', "#{Time.now.to_i}-opencover-report.xml")).gsub(/\//, '\\')

      FileUtils.mkdir_p(File.join('temp', 'opencover'))

      args = []
      args << '"' + opencover_path + '"'
      args << ' -target:' +  runner.runner_path
      args << ' -targetargs:"' + runner.runner_args.flatten.join(' ') + ' /noshadow"'
      args << ' -register:user'
      args << " -output:#{output_file}"

      log_debug 'Running opencover from "' + opencover_path + '"'
      execute_command :open_cover, args
    end

    def configuration
      config_with_defaults
    end

    def config_with_defaults
      @@defaults.merge @config
    end

  end

end