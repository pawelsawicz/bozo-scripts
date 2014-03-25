module Bozo::Hooks

  # Hooks for notifying Hipchat of the build
  #
  # The following env variables are required
  # - BUILD_URL
  # - BUILD_NAME
  #
  # with_hook :hipchat do |h|
  #   h.token   '.....'
  #   h.room_id 'Dev'
  #   h.name    'Bozo'
  #   h.notify  :failure
  # end
  #
  class Hipchat
    require 'net/http'
    require 'openssl'
    require 'json'

    COLOR_MAP = { pending: 'gray', success: 'green', failure: 'red' }

    def initialize
      @name = 'Bozo'
      @notify = []
    end

    def pre_build
      submit_notification(:pending, "Building #{project_name}")
    end

    def post_build
      submit_notification(:success, "Built #{project_name}")
    end

    def failed_build
      submit_notification(:failure, "Failed to build #{project_name}")
    end

    def token(token)
      @token = token
    end

    def room_id(room)
      @room = room
    end

    def name(name)
      @name = name
    end

    def notify(state)
      @notify << state
    end

    private

    def build_url
      env['BUILD_URL']
    end

    def build_number
      env['BUILD_NUMBER']
    end

    def project_name
      env['BUILD_NAME']
    end

    def submit_notification(state, description)
      return unless build_server?
      return unless @notify.include?(state)

      log_info "Notifying Hipchat of #{state} - #{description} - #{build_url}"

      message = "#{description} - <a href=\"#{build_url}\">view</a>"

      uri = URI("https://api.hipchat.com/v1/rooms/message?format=json&auth_token=#{@token}")
      header = {
        'Content-Type'  => 'application/x-www-form-urlencoded',
        'User-Agent'    => 'Bozo Hipchat notifier'
      }
      data = URI.encode_www_form({
                                     room_id: @room,
                                     from: @name,
                                     message: message,
                                     message_format: 'html',
                                     color: COLOR_MAP[state],
                                     notify: state == :failure ? '1' : '0'
                                 })

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.post(uri.request_uri, data, header)

      log_info "Notified Hipchat of #{state} - #{description} - #{build_url}"
    end

  end

end