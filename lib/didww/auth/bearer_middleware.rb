# frozen_string_literal: true
require 'faraday'

module DIDWW
  module Auth
    class BearerMiddleware < Faraday::Middleware
      # Options: audience [String] production hostname of the service called.

      UNAUTHENTICATED_PATH_SUFFIX = '/public_keys'
      REWIND_ERRORS = [
        IOError,
        SystemCallError
      ].freeze

      def call(env)
        return @app.call(env) if env.url.path.to_s.end_with?(UNAUTHENTICATED_PATH_SUFFIX)

        env.request_headers.delete('If-None-Match')
        token = authorize!(env)
        request_body = snapshot(env.request_body)
        response = @app.call(env)
        return response unless response.status == 401

        DIDWW::Client.token_provider.invalidate(audience, token.access_token)
        return response unless restore!(env, request_body)

        token = authorize!(env)
        @app.call(env).tap do |retried|
          DIDWW::Client.token_provider.invalidate(audience, token.access_token) if retried.status == 401
        end
      end

      private

      def audience
        options.fetch(:audience)
      end

      def authorize!(env)
        DIDWW::Client.token_provider.token_for(audience).tap do |token|
          env.request_headers['Authorization'] = "Bearer #{token.access_token}"
        end
      end

      def snapshot(body)
        body.is_a?(String) ? body.dup : body
      end

      def restore!(env, request_body)
        return false unless rewind_body(request_body)

        env.status = nil
        env.reason_phrase = nil
        env.response_headers = nil
        env.response_body = nil
        env.request_body = request_body
        true
      end

      def rewind_body(body)
        if body.nil? || body.is_a?(String)
          true
        elsif body.respond_to?(:rewind)
          body.rewind
          true
        else
          false
        end
      rescue *REWIND_ERRORS
        false
      end
    end
  end
end
