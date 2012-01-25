module Bozo::Publishers

  # Publisher that publishes gem files to rubygems.org
  class Rubygems

    def execute
      Dir['dist/gem/*.gem'].each { |gem| push gem }
    end

    private

    def push(gem)
      execute_command :rubygems, ['gem', 'push', gem]
    end

  end

end