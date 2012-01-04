require 'nokogiri'

module Bozo::TestRunners

  # Adds a code coverage test runner using dotCover
  #
  # The default configuration looks for dotCover in the ProgramFiles(x86) path
  #
  # Test runners can be defined for dotCover to run against. Each runner
  # produces a separate dotcover output
  class DotCover
    def self.default_path
      if ENV['teamcity.dotCover.home'].nil?
        log_debug 'Using dotcover from default installation directory'

        if ENV['ProgramFiles(x86)'].nil?
          program_files_path = ENV['ProgramFiles']
        else
          program_files_path = ENV['ProgramFiles(x86)']
        end

        File.join(program_files_path, 'JetBrains', 'dotCover', 'v1.2', 'Bin', 'dotcover.exe')
      else
        log_debug 'Using dotcover from teamcity.dotCover.home environment variable'
        File.join(ENV['teamcity.dotCover.home'], 'dotcover.exe')
      end
    end

    def initialize
      @@defaults = {
        :path => DotCover.default_path,
        :required => true
      }

      @config = {}
      @runners = []
    end

    # Returns whether dotcover is installed at the configured path
    def dotcover_installed?
      path = configuration[:path]

      return false if path.nil?

      File.exist? path
    end

    # Adds a test runner
    #
    # @param [Symbol] runner
    #     A test runner to wrap with dotcover
    def runner(runner, &block)
      add_instance @runners, Bozo::TestRunners, runner, block
    end

    # Specifies whether covering with dotcover is required
    #
    # If it is not required, and dotcover cannot be found, then test runners
    # are executed without coverage. If dotcover is required but cannot be
    # found then an error will occur.
    #
    # @param [boolean] required
    #     Whether dotCover coverage is required
    def required?(required)
      @config[:required] = required
    end

    def execute
      @runners.each do |runner|
        execute_with_coverage(runner) if (configuration[:required] || dotcover_installed?)

        execute_without_coverage(runner) unless configuration[:required]
      end
    end

    private

    # Resolves the named class within the given namespace and then created an
    # instance of the class before adding it to the given collection and
    # yielding it to the configuration block when one is provided.
    #
    # @param [Array] collection
    #     The collection the step executor should be added to once created.
    # @param [Module] namespace
    #     The module the named step executor should be found in.
    # @param [Symbol] type
    #     The name of the step executor.
    # @param [Proc] block
    #     Optional block to refine the configuration of the step executor.
    def add_instance(collection, namespace, type, block)
      instance = namespace.const_get(to_class_name(type)).new
      instance.extend Bozo::Runner
      collection << instance
      block.call instance if block
    end

    def execute_without_coverage(runner)
      log_debug 'Running ' + runner.class.to_s + ' without coverage'
      runner.execute
    end

    def execute_with_coverage(runner)
      if configuration[:required] & !dotcover_installed?
        log_fatal "Attempting to run with coverage but dotcover could not be found at #{configuration[:path]}"
      end

      log_debug "Running #{runner.class} with coverage"

      config = configuration
      dotcover_path = config[:path]
      coverage_path = generate_coverage_file runner

      args = []
      args << '"' + dotcover_path + '"'
      args << "analyse #{coverage_path}"

      log_debug 'Running dotcover from "' + dotcover_path + '"'
      execute_command :dot_cover, args
    end

    def generate_coverage_file(runner)
      output_file = File.expand_path(File.join('temp', 'dotcover', "#{Time.now.to_i}-dotcover-report.xml"))

      builder = Nokogiri::XML::Builder.new do |doc|
        doc.AnalyseParams do
          doc.Executable runner.runner_path.gsub(/\//, '\\')
          doc.Arguments runner.runner_args.join(' ')
          doc.WorkingDir File.expand_path(File.join('temp', 'dotcover'))
          doc.Output output_file
        end
      end

      coverage_path = File.expand_path(File.join('temp', 'dotcover', "coverage.xml"))
      FileUtils.mkdir_p File.dirname(coverage_path)
      File.open(coverage_path, 'w+') {|f| f.write(builder.to_xml)}

      coverage_path
    end

    def configuration
      config_with_defaults
    end

    def config_with_defaults
      @@defaults.merge @config
    end

  end

end