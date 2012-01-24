module Bozo::Publishers

  # Publisher that publishes gem files to rubygems.org
  class RubyGems

    def execute
      Dir['dist\gem\*.gem'].each { |gem| push gem }
    end

    private

    def push(gem)
      execute_command :gem, ['gem', 'push', gem]
    end

  end

end