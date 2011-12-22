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

    def self.hosted_in_teamcity?
      ENV['TEAMCITY_VERSION'] != nil
    end

    private

    def report
      report_types = [:nunit, :fx_cop]
      report_types.each do |type|
        reports = report_files(File.join(Dir.pwd, "/temp"), type)

        reports.each do |report|
          puts "##teamcity[importData type='#{type}' path='#{report}']"
        end
      end
    end

    def report_dotnetcoverage
      tool_types = [:dot_cover]
      
      tool_types.each do |type|
        reports = report_files(File.join(Dir.pwd, "/temp"), type)

        reports.each do |report|
          puts "##teamcity[importData type='dotNetCoverage' tool='#{to_class_name(type)}' path='#{report}']"
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
      files = File.expand_path(File.join(path, "/**/*-#{to_class_name(type)}-report.xml"))
      Dir[files]
    end

    # Converts a symbol into a Pascal Case class name.
    #
    # eg. `:single` => `"Single"`, `:two_words` => `"TwoWords"`.
    #
    # @param [Symbol] type
    #     The name of a step executor.
    def to_class_name(type)
      type.to_s.split('_').map{|word| word.capitalize}.join
    end

  end

end