module Bozo::TestRunners

  class Nunit
  
    def initialize
      @projects = []
    end
    
    def destination(destination)
      @destination = destination
    end
    
    def project(path)
      @projects << path
    end
    
    def report_path(path)
      @report_path = path
    end
    
    def to_s
      "Run tests with nunit against projects #{@projects}"
    end
    
    def execute
      args = []
      
      nunit_runners = expand_and_glob('packages', 'NUnit*', 'tools', 'nunit-console.exe')
      
      log_and_die 'No NUnit runners found. You must install one via nuget.' if nunit_runners.empty?
      log_and_die 'Multiple NUnit runners found. There should only be one.' if nunit_runners.size > 1
      
      nunit_runner = nunit_runners.first
      
      log_debug "Found runner at #{nunit_runner}"
      
      args << nunit_runner
      @projects.each do |project|
        expand_and_glob('temp', 'msbuild', project, '**', "#{project}.dll").each do |test_dll|
          args << "\"#{test_dll}\""
        end
      end
      args << '/nologo'
            
      report_path = @report_path
      report_path = expand_path('temp', 'nunit', 'nunit-report.xml') unless report_path
      
      # Ensure the directory is there because NUnit won't make it
      FileUtils.mkdir_p File.dirname(report_path)
      
      args << "/xml:\"#{report_path}\""
      
      execute_command :nunit, args
    end
    
    def expand_path(*args)
      File.expand_path(File.join(args))
    end
    
    def expand_and_glob(*args)
      Dir[expand_path(*args)]
    end
    
    def log_and_die(msg)
      log_fatal msg
      raise msg
    end
  
  end

end