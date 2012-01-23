require 'test/unit'

module Bozo::TestRunners

  class RubyTestUnit

    def initialize
      @paths = []
    end

    def path(path)
      @paths << path
    end

    def execute
      test_files = []

      @paths.each do |p|
        Dir[p].select {|f| (File.extname f) == '.rb'}.each {|f| test_files << f}
      end

      return unless test_files.any?

      raise Bozo::ExecutionError.new(:test_unit, test_files, -1) unless execute_tests test_files
    end

    private

    def execute_tests(test_files)
      Test::Unit::AutoRunner.run(true, nil, test_files)
    end

  end

end