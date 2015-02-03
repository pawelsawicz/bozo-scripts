module Bozo::Hooks

  class Jenkins

    def pre_build
      if Jenkins.hosted_in_jenkins?
        env['BUILD_URL'] = ENV['BUILD_URL']
        env['BUILD_NUMBER'] = ENV['BUILD_NUMBER']
        env['BUILD_NAME'] = ENV['JOB_NAME']
      end
    end

    def self.hosted_in_jenkins?
      not ENV['JENKINS_HOME'].nil?
    end

  end

end