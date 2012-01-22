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
        Dir[p].each { |file|
          test_files << file if (File.extname file) == '.rb'
        }
      end

      success = true
      success = Test::Unit::AutoRunner.run(true, nil, test_files) if test_files.any?

      raise "Failed running tests" unless success
    end
    
  end

end