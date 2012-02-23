module Bozo::TestRunners

  class Runit

    def initialize
      @paths = []
    end

    def path(path)
      @paths << path
    end

    def execute
      require 'test/unit'
      
      test_files = []

      @paths.each do |p|
        Dir[p].select {|f| (File.extname f) == '.rb'}.each {|f| test_files << f}
      end

      # raise an error if no test files were found. This may indicate a configuration issue
      raise Bozo::ConfigurationError.new "No tests found" unless test_files.any?
      raise Bozo::ExecutionError.new(:runit, test_files, -1) unless execute_tests test_files
    end

    private

    def execute_tests(test_files)
      Test::Unit::AutoRunner.run(true, nil, test_files)
    end

  end

end