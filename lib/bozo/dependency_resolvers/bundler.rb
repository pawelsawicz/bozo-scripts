module Bozo::DependencyResolvers

  # Class for resolving dependencies using Bundler.
  class Bundler

    # Creates a new instance.
    def initialize
      @pre = false
    end

    # Ensures Bundler is installed and then calls installs the gems specified
    # in your Gemfile.
    def execute
      ensure_bundler_installed
      install_gems
    end

    # Decides whether when installing Bundler if the pre version of the gem
    # should be installed.
    #
    # @param [Boolean] pre
    #     Whether the pre version of the Bundler gem should be installed.
    #     Defaults to <tt>false</tt> if not specified.
    def use_pre(pre)
      @pre = pre
    end

    private

    # Interrogates the list of installed gems and installs Bundler if it is
    # not found.
    def ensure_bundler_installed
      return if `gem list bundler`.include? 'bundler'

      args = %w{gem install --no-rdoc --no-ri bundler}
      args << '--pre' if @pre

      execute_command :rubygems, args
    end

    # Executes Bundler's install command, placing all of the installed gems
    # into the <tt>build/bundler</tt> directory.
    def install_gems
      execute_command :bundler, %w{bundle install --path build/bundler}
    end

  end

end