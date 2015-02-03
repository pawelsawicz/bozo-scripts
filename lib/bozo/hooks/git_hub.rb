module Bozo::Hooks

  # Hooks for notifying GitHub of the build
  #
  # The following env variables are required
  # - BUILD_URL
  # - BUILD_NUMBER
  #
  # with_hook :git_hub do |h|
  #   h.token '.....'
  #   h.owner 'zopaUK'
  #   h.repo  'bozo-scripts'
  # end
  #
  class GitHub
    require 'net/http'
    require 'openssl'
    require 'json'

    def pre_build
      submit_notification(:pending, "Build #{build_number} pending")
    end

    def post_build
      submit_notification(:success, "Build #{build_number} succeeded")
    end

    def failed_build
      submit_notification(:failure, "Build #{build_number} failed")
    end

    def token(token)
      @token = token
    end

    def owner(owner)
      @owner = owner
    end

    def repo(repo)
      @repo = repo
    end

    private

    def build_url
      env['BUILD_URL']
    end

    def build_number
      env['BUILD_NUMBER']
    end

    def submit_notification(state, description)
      return unless build_server?

      log_info "Notifying GitHub of #{state} - #{description} - #{build_url}"

      commit = `git rev-parse HEAD`

      uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/statuses/#{commit}")
      header = {
        'Content-Type'  => 'application/json',
        'Authorization' => "token #{@token}",
        'User-Agent'    => 'Bozo GitHub notifier'
      }
      data = { state: state, description: description, target_url: build_url}.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.post(uri.request_uri, data, header)

      log_info "Notified GitHub of #{state} - #{description} - #{build_url}"
    end

  end

end
