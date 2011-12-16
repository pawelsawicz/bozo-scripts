module Bozo::Hooks

  class GitCommitHashes
    
    def post_dependencies
      Bozo::ENV['GIT_HASH'] = `git log -1 --format="%h"`.strip
      Bozo::ENV['GIT_HASH_FULL'] = `git log -1 --format="%H"`.strip
    end
    
  end

end