module Bozo::Hooks

  class BuildNumberVersion

  	def post_dependencies
      env['GIT_HASH_FULL'] = `git log -1 --format="%H"`.strip
      env['BUILD_VERSION'] = build_version
  	end

  	private

  	def build_version
  	  if pre_release?
  	  	Bozo::Versioning::Version.new(env['BUILD_NUMBER'],0,0)
  	  else
  	  	version
  	  end
  	end
  
  end

end