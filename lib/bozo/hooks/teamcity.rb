module Bozo::Hooks

  class Teamcity

    def pre_compile
      return unless Teamcity.hosted_in_teamcity?
      log_pre_step :compile
      version = Bozo::Configuration.version

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

      # only supporting nunit at present
      report_path = File.expand_path(File.join(Dir.pwd, "/temp/nunit/#{t}-report.xml"))
      puts "##teamcity[importData type='#{t}' path='#{report_path}']" if File.exist? report_path

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

    def log_pre_step(step)
      puts "##teamcity[progressStart 'Pre #{step}']" if Teamcity.hosted_in_teamcity?
    end

    def log_post_step(step)
      puts "##teamcity[progressEnd 'Post #{step}']" if Teamcity.hosted_in_teamcity?
    end

    def self.hosted_in_teamcity?
      ENV['TEAMCITY_VERSION'] != nil
    end

  end

end