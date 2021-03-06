module Bozo::Hooks

  class GitCommitHashes
    
    def pre_prepare
      env['GIT_HASH'] = `git log -1 --format="%h"`.strip
      env['GIT_HASH_FULL'] = `git log -1 --format="%H"`.strip
      env['BUILD_VERSION'] = version
      env['BUILD_VERSION_FULL'] = build_version
    end

    private

    def build_version
      if pre_release?
        Bozo::Versioning::Version.new(version.major, version.minor, version.patch, "pre#{env['GIT_HASH']}")
      else
        version
      end
    end
    
  end

end