module Bozo::TestRunners

  # A TestRunner for NUnit
  # By default the x64 runner is used. If you want to use a different
  # platform runner then set the platform, e.g. 'x86'.
  #
  # == Dotcover integration
  # To enable integration with the dotcover test runner the following
  # interface needs to be used
  #
  #   runner_path # should return the path to the runners executable
  #   runner_args # should return the arguments to be passed to use
  class Nunit
  
    def initialize
      @projects = []
      @include = []
      @exclude = []
    end
    
    def destination(destination)
      @destination = destination
    end

    def platform(platform)
      @platform = platform
    end
    
    def project(path)
      @projects << path
    end
    
    def report_path(path)
      @report_path = path
    end

    def coverage(coverage)
      @coverage = coverage
    end

    def include(include)
      @include << include
    end

    def exclude(exclude)
      @exclude << exclude
    end
    
    def to_s
      "Run tests with nunit against projects #{@projects}"
    end

    # Returns the path to the runner's executable.
    #
    # @returns [String]
    def runner_path
      exe_name = "nunit-console.exe"

      if defined? @platform
        log_debug "Looking for runner with #@platform platform"
        exe_name = "nunit-console-#@platform.exe"
      end

      nunit_runners = expand_and_glob('packages', 'NUnit*', 'tools', exe_name)
      raise nunit_runner_not_found if nunit_runners.empty?
      raise multiple_runners_found if nunit_runners.size > 1

      nunit_runner = nunit_runners.first

      log_debug "Found runner at #{nunit_runner}"

      nunit_runner
    end

    # Returns the arguments required for the runner's executable.
    #
    # @returns [Array]
    def runner_args
      args = []

      @projects.each do |project|
        expand_and_glob('temp', 'msbuild', project, '**', "#{project}.dll").each do |test_dll|
          args << "\"#{test_dll}\""
        end
      end
      args << '/nologo'

      report_path = @report_path
      report_path = expand_path('temp', 'nunit', "#{Time.now.to_i}-nunit-report.xml") unless report_path

      # Ensure the directory is there because NUnit won't make it
      FileUtils.mkdir_p File.dirname(report_path)

      args << "/xml:\"#{report_path}\""
      args << "/include:#{@include.join(',')}" if @include.any?
      args << "/exclude:#{@exclude.join(',')}" if @exclude.any?

      args
    end
    
    def execute
      execute_command :nunit, [runner_path] << runner_args
    end

    private

    def nunit_runner_not_found
      Bozo::ConfigurationError.new 'No NUnit runners found. You must install one via nuget.'
    end

    def multiple_runners_found
      Bozo::ConfigurationError.new 'Multiple NUnit runners found. There should only be one.'
    end
    
    def expand_path(*args)
      File.expand_path(File.join(args))
    end
    
    def expand_and_glob(*args)
      Dir[expand_path(*args)]
    end
  
  end

end