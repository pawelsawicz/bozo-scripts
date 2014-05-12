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
      version_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/../../../VERSION')

      if pre_release?
        File.open(version_file, 'w') { |f| f << "#{version}.pre#{env['GIT_HASH']}" }
      end

      begin
        execute_command :rubygems, ['gem', 'build', spec]
      ensure
        if pre_release?
          File.open(version_file, 'w') { |f| f << version.to_s }
        end
      end
    end

  end

end