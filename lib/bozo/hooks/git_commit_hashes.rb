module Bozo::Hooks

  class GitCommitHashes
    
    def post_dependencies
      env['GIT_HASH'] = `git log -1 --format="%h"`.strip
      env['GIT_HASH_FULL'] = `git log -1 --format="%H"`.strip
    end
    
  end

end