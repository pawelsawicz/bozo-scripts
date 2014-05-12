module Bozo::Packagers

  # Specifies gem packager.
  #
  # Builds any '*.gemspec' file in the root directory
  class Rubygems

    def execute
      dist_dir = File.expand_path(File.join('dist', 'gem'))
      FileUtils.mkdir_p dist_dir

      Dir['*.gemspec'].each { |spec| build_gem spec }
      Dir['*.gem'].each { |file| FileUtils.mv file, File.join(dist_dir, file) }
    end

    private

    def build_gem(spec)
      if pre_release?
        package_version.write_to_file
      end

      begin
        execute_command :rubygems, ['gem', 'build', spec]
      ensure
        if pre_release?
          version.write_to_file
        end
      end
    end

    def package_version
      RubyGemVersion.parse(env['BUILD_VERSION'])
    end

    class RubyGemVersion < Bozo::Versioning::Version

      def self.parse(version)
        new version.major, version.minor, version.patch, version.extension
      end

      def to_s
        "#{major}.#{minor}.#{patch}.#{extension}"
      end

    end

  end

end