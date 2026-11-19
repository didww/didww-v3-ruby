# frozen_string_literal: true
require 'didww/http'

module DIDWW
  # :nodoc:
  class BaseMiddleware < Faraday::Middleware
    def call(request_env)
      request_env[:request_headers].merge!(request_headers(request_env))
      request_env.url.host = URI(DIDWW::Client.api_base_url).host

      @app.call(request_env).on_complete do |_response_env|
        # do something with the response
        # _response_env[:response_headers].merge!(...)
      end
    end

    private

    def request_headers(_request_env)
      {
        'User-Agent' => DIDWW::Http::USER_AGENT,
      }
    end
  end
end
