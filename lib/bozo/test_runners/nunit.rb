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
      @execute_in_parallel = false
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
      cannot_define_both_include_and_exclude_categories if @exclude.any?
      @include << include
    end

    def exclude(exclude)
      cannot_define_both_include_and_exclude_categories if @include.any?
      @exclude << exclude
    end

    def execute_in_parallel
      @execute_in_parallel = true
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
    def runner_args(projects = nil, report_prefix = nil)
      projects = @projects if projects.nil?
      report_prefix = Time.now.to_i if report_prefix.nil?

      args = []

      projects.each do |project|
        expand_and_glob('temp', 'msbuild', project, '**', "#{project}.dll").each do |test_dll|
          args << "\"#{test_dll}\""
        end
      end
      args << '/nologo'

      report_path = @report_path
      report_path = expand_path('temp', 'nunit', "#{report_prefix}-nunit-report.xml") unless report_path

      # Ensure the directory is there because NUnit won't make it
      FileUtils.mkdir_p File.dirname(report_path)

      args << "/xml:\"#{report_path}\""
      args << "/include:#{@include.join(',')}" if @include.any?
      args << "/exclude:#{@exclude.join(',')}" if @exclude.any?

      args
    end
    
    def execute
      if @execute_in_parallel
        failed_projects = Queue.new
        threads = []

        @projects.each do |project|
          t = Thread.new {
            begin
              execute_command :nunit, [runner_path] << runner_args([project], "#{project}-#{Time.now.to_i}")
            rescue
              failed_projects.push(project)
            end
          }
          threads.push(t)
        end

        threads.each(&:join)

        failed = []
        until failed_projects.empty?
          failed << failed_projects.pop
        end

        if failed.length > 0
          raise Bozo::ExecutionError.new(:nunit, [runner_path] << failed, 1)
        end
      else
        execute_command :nunit, [runner_path] << runner_args
      end
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

    def cannot_define_both_include_and_exclude_categories
      raise Bozo::ConfigurationError.new 'Both include and exclude categories defined. You cannot specify both for nunit.'
    end
  
  end

end