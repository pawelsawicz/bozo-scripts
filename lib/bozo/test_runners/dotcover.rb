require 'nokogiri'

module Bozo::TestRunners

  class DotCover

    @@defaults = {
      :path => File.join(ENV['ProgramFiles(x86)'], 'JetBrains', 'dotCover', 'v1.2', 'Bin', 'dotcover.exe')
    }

    def initialize
      @config = {}
      @runners = []
    end

    def runner(runner, &block)
      Bozo::Configuration.add_instance @runners, Bozo::TestRunners, runner, block
    end

    def execute
      config = configuration
      
      @runners.each do |runner|
        coverage_path = generate_coverage_file runner

        dotcover_path = config[:path]

        args = []
        args << '"' + dotcover_path + '"'
        args << "analyse #{coverage_path}"

        Bozo.log_debug 'Running dotcover from "' + dotcover_path + '"'
        Bozo.execute_command :dot_cover, args
      end
    end

    private

    def generate_coverage_file(runner)
      builder = Nokogiri::XML::Builder.new do |doc|
        doc.AnalyseParams do
          doc.Executable runner.runner_path.gsub(/\//, '\\')
          doc.Arguments runner.runner_args.join(' ')
          doc.WorkingDir File.expand_path(File.join('temp', 'dotcover'))
          doc.Output File.expand_path(File.join('temp', 'dotcover', 'dotcover-report.xml'))
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