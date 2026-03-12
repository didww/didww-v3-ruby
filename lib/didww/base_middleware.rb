# frozen_string_literal: true
module DIDWW
  # :nodoc:
  class BaseMiddleware < Faraday::Middleware
    def call(request_env)
      request_env[:request_headers].merge!(request_headers(request_env))
      request_env.url.host = URI(DIDWW::Client.api_base_url).host

      @app.call(request_env).on_complete do |response_env|
        # do something with the response
        # response_env[:response_headers].merge!(...)
      end
    end

    private

    def request_headers(request_env)
      headers = {
        'User-Agent' => "didww-v3 Ruby gem v#{VERSION}",
      }
      headers['Api-Key'] = DIDWW::Client.api_key unless request_env.url.path&.end_with?('/public_keys')
      headers['x-didww-api-version'] = DIDWW::Client.api_version unless DIDWW::Client.api_version.blank?
      headers
    end
  end
end
