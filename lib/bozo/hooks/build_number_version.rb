module Bozo::Hooks

  class BuildNumberVersion

  	def post_dependencies
      env['GIT_HASH_FULL'] = `git log -1 --format="%H"`.strip
      env['BUILD_VERSION']= build_version
      build_version.write_to_file
    end

  	private

  	def build_version
  	  if env['BUILD_NUMBER']
  	  	Bozo::Versioning::Version.new(version.major, version.minor, env['BUILD_NUMBER'])
  	  else
  	  	version
  	  end
  	end
  
  end

end