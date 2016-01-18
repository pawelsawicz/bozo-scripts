module Bozo::Hooks

  # Hook to create a release in Octopus.
  class OctopusCreateRelease

    def initialize
      @deploy_to = nil
      @display_progress = false
    end

    def required_tools
      :octopus_tools
    end

    # Specify the name of the Octopus Deploy project to create a release for.
    def project(value)
      @octopus_project = value
    end

    # The server address of Octopus.
    def server(value)
      @octopus_server = value
    end

    # The api key to authorise to Octopus with.
    def api_key(value)
      @octopus_api_key = value
    end

    # Specify the environment in Octopus to deploy to.
    def deploy_to(value)
      @deploy_to = value
    end

    # Write the deployment log from Octopus. If false
    # then the hook does not wait for the release to complete.
    def display_progress(value)
      @display_progress = value
    end

    def post_publish
      return unless build_server?
      log_info "Creating release in Octopus for #{env['BUILD_VERSION_FULL']}"

      args = []
      args << File.expand_path(File.join('build', 'tools', 'octopustools', 'Octo.exe'))
      args << 'create-release'
      args << "--project \"#{@octopus_project}\""
      args << "--version #{env['BUILD_VERSION_FULL']}"
      args << "--packageversion #{env['BUILD_VERSION_FULL']}"
      args << "--server #{@octopus_server}"
      args << "--apiKey #{@octopus_api_key}"
      args << "--releaseNotes \"[Build #{env['BUILD_VERSION_FULL']}](#{env['BUILD_URL']})\""

      if @display_progress
        args << '--progress'
      end

      if @deploy_to
        args << "--deployto=#{@deploy_to}"
      end

      execute_command :octo, args
    end

  end

end