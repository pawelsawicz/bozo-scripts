module Bozo::Hooks

  # Hook to tag a git repository when a release is published from a build
  # server.
  class GitTagRelease

    def post_publish
      return unless build_server?
      log_info "Tagging repository for release #{env['BUILD_VERSION_FULL']}"

      tag_name = "rel-#{env['BUILD_VERSION_FULL']}"

      if `git tag`.split("\n").include? tag_name
        log_warn "The tag #{tag_name} already exists"
      else
        execute_command :git, ['git', 'tag', tag_name]
        execute_command :git, ['git', 'push', '--tags']
      end
    end

  end

end