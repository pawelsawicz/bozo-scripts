module Bozo::Hooks

  class Teamcity

    def pre_compile
      return unless Teamcity.hosted_in_teamcity?
      log_pre_step :compile

      puts "##teamcity[buildNumber '#{version}']"
      # currently a general compiler which wraps everything. Once a compiler hook is added can distinguish
      # each specific compiler
      puts "##teamcity[compilationStarted compiler='Bozo']"
    end

    def post_compile
      return unless Teamcity.hosted_in_teamcity?
      puts "##teamcity[compilationFinished compiler='Bozo']"
      log_post_step :compile
    end

    def post_test
      return unless Teamcity.hosted_in_teamcity?

      report
      report_dotnetcoverage

      log_post_step :test
    end

    def method_missing(method, *args)
      if method.to_s =~ /^(pre|post)_(.+)/
        send "log_#{$1}_step".to_sym, $2
      else
        super
      end
    end

    def respond_to?(method)
      method.to_s =~ /^(pre|post)_(.+)/ or super
    end

    # Returns whether teamcity is hosting bozo
    def self.hosted_in_teamcity?
      not ENV['TEAMCITY_VERSION'].nil?
    end

    private

    # Notifies teamcity of general reports such as test runner results
    def report
      report_types = [:nunit, :fxcop]
      report_types.each do |type|
        reports = report_files(File.join(Dir.pwd, "/temp"), type)

        reports.each do |report|
          puts "##teamcity[importData type='#{type}' path='#{report}']"
        end
      end
    end

    # Notifies teamcity of dotNetCoverage results
    def report_dotnetcoverage
      tool_types = [:dot_cover]
      
      tool_types.each do |type|
        reports = report_files(File.join(Dir.pwd, "/temp"), type)

        reports.each do |report|
          tool_name = Bozo::Configuration.to_class_name(type).downcase
          puts "##teamcity[importData type='dotNetCoverage' tool='#{tool_name}' path='#{report}']"
        end
      end
    end

    def log_pre_step(step)
      puts "##teamcity[progressStart 'Pre #{step}']" if Teamcity.hosted_in_teamcity?
    end

    def log_post_step(step)
      puts "##teamcity[progressEnd 'Post #{step}']" if Teamcity.hosted_in_teamcity?
    end

    def report_files(path, type)
      files = File.expand_path(File.join(path, "/**/*-#{Bozo::Configuration.to_class_name(type)}-report.xml"))
      Dir[files]
    end

  end

end