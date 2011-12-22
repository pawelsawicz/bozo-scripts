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
      if ENV['TEAMCITY_VERSION'].nil?
        File.join(ENV['ProgramFiles(x86)'], 'JetBrains', 'dotCover', 'v1.2', 'Bin', 'dotcover.exe')
      else
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

    def dotcover_installed?
      path = configuration[:path]
      Bozo.log_debug "checking whether dotcover is installed at #{path}"
      exists = File.exist? path

      Bozo.log_debug "Dotcover is installed" if exists
      Bozo.log_debug "Dotcover is not installed" unless exists

      exists
    end

    # Adds a test runner
    #
    # @param [Symbol] runner
    #     The test runner to wrap with dotcover
    def runner(runner, &block)
      Bozo::Configuration.add_instance @runners, Bozo::TestRunners, runner, block
    end

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

    def execute_without_coverage(runner)
      Bozo.log_debug 'Running ' + runner + ' without coverage'
      runner.execute
    end

    def execute_with_coverage(runner)
      Bozo.log_debug 'Running ' + runner + ' with coverage'

      config = configuration
      dotcover_path = config[:path]
      coverage_path = generate_coverage_file runner

      args = []
      args << '"' + dotcover_path + '"'
      args << "analyse #{coverage_path}"

      Bozo.log_debug 'Running dotcover from "' + dotcover_path + '"'
      Bozo.execute_command :dot_cover, args
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