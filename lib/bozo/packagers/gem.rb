require 'rubygems'
require 'rubygems/package_task'

module Bozo::Packagers

  # Specifies gem packager.
  #
  # Builds any '*.gemspec' file in the root directory
  class Gem

    def execute
      dist_dir = File.expand_path(File.join('dist', 'gem'))
      FileUtils.mkdir_p dist_dir

      gemspecs = []
      Dir['*.gemspec'].each { |file| gemspecs << File.expand_path(file) }

      Dir.chdir(dist_dir) do
        gemspecs.each do |spec_file|
          spec = eval(File.read(spec_file))

          Gem::PackageTask.new(spec)
        end
      end
    end

  end

end