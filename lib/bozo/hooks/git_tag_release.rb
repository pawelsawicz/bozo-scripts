module Bozo::Hooks

  # Hook to tag a git repository when a release is published from a build
  # server.
  class GitTagRelease

    def post_publish
      return unless build_server?
      log_info "Tagging repository for release #{version}"

      tag_name = "rel-#{version}"

      if `git tag`.split("\n").include? tag_name
        raise Bozo::ConfigurationError.new "The tag #{tag_name} already exists"
      end

      execute_command :git, ['git', 'tag', tag_name]
      execute_command :git, ['git', 'push', '--tags']
    end

  end

end