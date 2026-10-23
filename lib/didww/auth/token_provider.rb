# frozen_string_literal: true
require 'digest'
require 'json'
require 'active_support/notifications'
require 'didww/errors'
require 'didww/http'
require 'didww/auth/token'

module DIDWW
  module Auth
    class TokenProvider
      CACHE_KEY_PREFIX = 'didww:token:v1:'
      NOTIFICATION = 'mint_token.didww'
      BACKOFF_BASE = 0.5
      BACKOFF_CAP = 8
      MAX_ATTEMPTS = 4
      RETRY_SPREAD_RATIO = 0.2
      MIN_RETRY_SPREAD = 1
      TIMEOUT = 10
      TRANSPORT_ERRORS = [
        Faraday::ConnectionFailed,
        Faraday::TimeoutError
      ].freeze

      def initialize(sleeper: ->(seconds) { sleep(seconds) }, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @sleeper = sleeper
        @clock = clock
        @lock = Mutex.new
        @key_locks = {}
        @blocked_until = {}
        @failures = {}
      end

      # @param audience [String] production hostname of the service called
      # @return [DIDWW::Auth::Token]
      # @raise [DIDWW::Auth::Error]
      def token_for(audience)
        key = cache_key(audience)
        cached_token(key) || begin
          failure_seen = last_failure(key)
          key_lock(key).synchronize { cached_token(key) || raise_failure_since!(key, failure_seen) || mint!(key, audience) }
        end
      end

      # Evicts the cached token only while it is still the one that was refused,
      # so a token another thread has just minted survives.
      def invalidate(audience, access_token)
        key = cache_key(audience)
        key_lock(key).synchronize { store.delete(key) if cached_token(key)&.access_token == access_token }
      end

      private

      def store
        DIDWW::Client.token_store
      end

      def logger
        DIDWW::Client.logger
      end

      def cache_key(audience)
        parts = [
          DIDWW::Client.auth_base_url,
          api_key_digest,
          audience,
          DIDWW::Client.api_version,
          DIDWW::Client.scope || '-'
        ]
        CACHE_KEY_PREFIX + Digest::SHA256.hexdigest(parts.join("\n"))
      end

      def rate_limit_key
        [DIDWW::Client.auth_base_url, api_key_digest].join("\n")
      end

      def api_key_digest
        Digest::SHA256.hexdigest(DIDWW::Client.api_key.to_s)
      end

      def key_lock(key)
        @lock.synchronize { @key_locks[key] ||= Mutex.new }
      end

      def cached_token(key)
        data = store.read(key)
        Token.from_h(data) if data
      end

      def last_failure(key)
        @lock.synchronize { @failures[key] }
      end

      # Callers queued behind a mint that failed raise its error instead of repeating the retries.
      def raise_failure_since!(key, failure_seen)
        failure = last_failure(key)
        raise failure if failure && !failure.equal?(failure_seen)
      end

      def mint!(key, audience)
        raise_if_rate_limited!
        token = request_token!(token_request(audience))
        store.write(key, token.to_h, expires_in: token.expires_in)
        token
      rescue ServerError, ConnectionError => e
        @lock.synchronize { @failures[key] = e }
        raise
      end

      def request_token!(request)
        ActiveSupport::Notifications.instrument(NOTIFICATION, aud: request[:aud], scope_requested: request[:scope]) do |payload|
          token_from!(post_token!(request)).tap do |token|
            verify_grant!(token, request)
            payload.merge!(aud: token.aud, scope_granted: token.scope, api_version: token.api_version, expires_in: token.expires_in)
          end
        end
      end

      def token_request(audience)
        request = { aud: [audience], api_version: DIDWW::Client.api_version }
        request[:scope] = DIDWW::Client.scope.to_s if DIDWW::Client.scope
        request
      end

      def raise_if_rate_limited!
        blocked_until = @lock.synchronize { @blocked_until[rate_limit_key] }
        remaining = blocked_until && blocked_until - @clock.call
        if remaining&.positive?
          raise RateLimited.new(status: 429, error: 'rate_limit_exceeded', retry_after: remaining.ceil)
        end
      end

      def post_token!(request, attempt = 1)
        response = auth_connection.post('token', JSON.generate(request), token_headers)
        return response if response.status < 500 || attempt == MAX_ATTEMPTS

        backoff!(attempt)
        post_token!(request, attempt + 1)
      rescue Faraday::SSLError => e
        raise ConnectionError.new(e.message)
      rescue *TRANSPORT_ERRORS => e
        raise ConnectionError.new(e.message) if attempt == MAX_ATTEMPTS

        backoff!(attempt)
        post_token!(request, attempt + 1)
      end

      def auth_connection
        DIDWW::Http.connection(DIDWW::Client.auth_base_url, timeout: TIMEOUT)
      end

      def token_headers
        {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Api-Key' => DIDWW::Client.api_key.to_s
        }
      end

      def backoff!(attempt)
        @sleeper.call(rand * [BACKOFF_CAP, BACKOFF_BASE * (2**attempt)].min)
      end

      # Spreads the next mints of processes that got the same Retry-After.
      def retry_window(retry_after)
        retry_after + (rand * [MIN_RETRY_SPREAD, RETRY_SPREAD_RATIO * retry_after].max)
      end

      def token_from!(response)
        body = parse_body(response.body)
        error_fields = { status: response.status, error: body['error'], error_description: body['error_description'] }
        case response.status
        when 200
          Token.from_h(body.merge('minted_at' => Time.now.to_i))
        when 400
          raise InvalidRequest.new(**error_fields)
        when 401
          raise InvalidClient.new(**error_fields)
        when 429
          retry_after = [response.headers['Retry-After'].to_i, 1].max
          @lock.synchronize { @blocked_until[rate_limit_key] = @clock.call + retry_window(retry_after) }
          raise RateLimited.new(**error_fields, retry_after: retry_after)
        when 500..599
          raise ServerError.new(**error_fields)
        else
          raise Error.new(**error_fields)
        end
      end

      def parse_body(body)
        parsed = JSON.parse(body.to_s)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end

      def verify_grant!(token, request)
        audience = request[:aud].first
        if token.access_token.blank? || !token.aud.include?(audience)
          raise InvalidGrant.new("Token service granted audience #{token.aud.inspect}, requested #{audience}", status: 200)
        end

        if request[:scope] && token.scope != request[:scope]
          logger&.warn("DIDWW token scope mismatch: requested #{request[:scope]}, granted #{token.scope}")
        end
        if token.api_version != request[:api_version]
          logger&.warn("DIDWW token api_version mismatch: requested #{request[:api_version]}, granted #{token.api_version}")
        end
      end
    end
  end
end
