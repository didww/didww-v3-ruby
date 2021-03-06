# frozen_string_literal: true
module DIDWW
  # :nodoc:
  class JsonapiMiddleware < Faraday::Middleware
    def call(request_env)
      headers = {}
      headers['Content-Type']        = 'application/vnd.api+json'
      headers['Api-Key']             = DIDWW::Client.api_key
      headers['User-Agent']          = "didww-v3 Ruby gem v#{VERSION}"
      headers['x-didww-api-version'] = DIDWW::Client.api_version unless DIDWW::Client.api_version.blank?

      request_env[:request_headers].merge!(headers)
      request_env.url.host = URI(DIDWW::Client.api_base_url).host

      @app.call(request_env).on_complete do |response_env|
        # do something with the response
        # response_env[:response_headers].merge!(...)
      end
    end
  end
end
