# frozen_string_literal: true
require 'faraday'
require 'didww/version'

module DIDWW
  module Http
    USER_AGENT = "didww-v3 Ruby gem v#{DIDWW::VERSION}"
    OPEN_TIMEOUT = 10
    TIMEOUT = 60
    FILTERED_HEADERS = /^(Api-Key|Authorization): .*$/i

    # The block receives the connection before the bearer middleware is added,
    # so middleware registered there wraps the authenticated request.
    # @param url [String]
    # @param audience [String,nil] token audience; nil sends no Authorization header
    # @param timeout [Integer] read timeout in seconds
    # @return [Faraday::Connection]
    def self.connection(url, audience: nil, timeout: TIMEOUT)
      Faraday.new(url: url, headers: { 'User-Agent' => USER_AGENT }) do |connection|
        connection.options.open_timeout = OPEN_TIMEOUT
        connection.options.timeout = timeout
        if DIDWW::Client.http_verbose?
          connection.response :logger, nil, headers: true do |formatter|
            formatter.filter(FILTERED_HEADERS, '\1: [FILTERED]')
          end
        end
        yield(connection) if block_given?
        connection.use DIDWW::Auth::BearerMiddleware, audience: audience if audience
        connection.adapter Faraday.default_adapter
        DIDWW::Client._customize_faraday_block&.call(connection)
      end
    end
  end
end
