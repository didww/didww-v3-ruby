# frozen_string_literal: true
require 'active_support/core_ext/object/blank'
require 'json_api_client'

module DIDWW
  class Error < StandardError
  end

  # @api private
  module RetryAfter
    # @param value [String,nil] the Retry-After header
    # @return [Integer,nil] the delay in seconds, nil when the header is missing or is an HTTP date
    def self.seconds(value)
      value.to_i if value&.match?(/\A\d+\z/)
    end
  end

  # A 429 from the API, raised by resource calls and Export#download. It is not retried.
  class TooManyRequests < JsonApiClient::Errors::TooManyRequests
    STATUS_HANDLERS = { 429 => ->(env) { raise DIDWW::TooManyRequests, env } }.freeze

    # @return [Integer,nil] seconds to wait before the next request, from Retry-After
    def retry_after
      RetryAfter.seconds(env.response_headers['Retry-After']) if env
    end
  end

  module Auth
    class Error < DIDWW::Error
      attr_reader :status, :error, :error_description, :retry_after

      def initialize(message = nil, status: nil, error: nil, error_description: nil, retry_after: nil)
        @status = status
        @error = error
        @error_description = error_description
        @retry_after = retry_after
        super(message || [error, error_description].compact.join(': ').presence || "Token service responded with status #{status}")
      end
    end

    class InvalidClient < Auth::Error
    end

    class InvalidRequest < Auth::Error
    end

    class RateLimited < Auth::Error
    end

    class ServerError < Auth::Error
    end

    class ConnectionError < Auth::Error
    end

    class InvalidGrant < Auth::Error
    end
  end

  module Prices
    class Error < DIDWW::Error
      attr_reader :status, :code, :errors, :retry_after

      def initialize(message = nil, status: nil, code: nil, errors: [], retry_after: nil)
        @status = status
        @code = code
        @errors = errors
        @retry_after = retry_after
        super(message || errors.map { |e| e['detail'] || e['title'] }.compact.join('; ').presence || "Prices service responded with status #{status}")
      end
    end

    class BadRequest < Prices::Error
    end

    class NotAuthorized < Prices::Error
    end

    class AccessDenied < Prices::Error
    end

    class PricePlanNotAssigned < Prices::Error
    end

    class PriceNotFound < Prices::Error
    end

    class NotAcceptable < Prices::Error
    end

    class TooManyRequests < Prices::Error
    end

    class ServiceUnavailable < Prices::Error
    end

    class ConnectionError < Prices::Error
    end

    class UnexpectedStatus < Prices::Error
    end
  end
end
