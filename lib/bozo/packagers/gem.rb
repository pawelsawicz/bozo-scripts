module Bozo::Packagers

  # Specifies gem packager.
  #
  # Builds any '*.gemspec' file in the root directory
  class Gem

    def execute
      dist_dir = File.expand_path(File.join('dist', 'gem'))
      FileUtils.mkdir_p dist_dir

      Dir['*.gemspec'].each { |spec| build_gem spec }
      Dir['*.gem'].each { |file| FileUtils.mv file, File.join(dist_dir, file) }
    end

    private

    def build_gem(spec)
      execute_command :gem, ['gem', 'build', spec]
    end

  end

end