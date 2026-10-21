# frozen_string_literal: true
require 'active_support/core_ext/object/blank'

module DIDWW
  class Error < StandardError
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

    class InvalidClient < Error
    end

    class InvalidRequest < Error
    end

    class RateLimited < Error
    end

    class ServerError < Error
    end

    class ConnectionError < Error
    end

    class InvalidGrant < Error
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

    class BadRequest < Error
    end

    class NotAuthorized < Error
    end

    class AccessDenied < Error
    end

    class PricePlanNotAssigned < Error
    end

    class PriceNotFound < Error
    end

    class NotAcceptable < Error
    end

    class TooManyRequests < Error
    end

    class ServiceUnavailable < Error
    end

    class ConnectionError < Error
    end

    class UnexpectedStatus < Error
    end
  end
end
