module Bozo::Hooks

  # Hook to tag a git repository when a release is published from a build
  # server.
  class GitTagRelease

    def post_publish
      return unless Bozo::Configuration.build_server
      Bozo.log_info "Tagging repository for release #{Bozo::Configuration.version}"

      tag_name = "rel-#{Bozo::Configuration.version}"

      if `git tag`.split("\n").include? tag_name
        raise Bozo::ConfigurationError.new "The tag #{tag_name} already exists"
      end

      Bozo.execute_command :git, ['git', 'tag', tag_name]
      Bozo.execute_command :git, ['git', 'push', '--tags']
    end

  end

end