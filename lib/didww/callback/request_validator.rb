# frozen_string_literal: true
require 'openssl'

module DIDWW
  module Callback
    # @example
    #   validator = DIDWW::Callback::RequestValidator.new(api_key)
    #   uri = request.original_url
    #   if request.post?
    #     # Collect all parameters passed from DIDWW.
    #     params = env['rack.request.form_hash']
    #   else
    #     params = env['rack.request.query_hash']
    #   end
    #
    # signature = env['HTTP_X_DIDWW_SIGNATURE']
    # validator.validate(uri, params, signature) #=> true if the request is from DIDWW
    # # or with rails
    class RequestValidator
      DIGEST_ALGO = 'SHA1'
      HEADER = 'X-DIDWW-Signature'

      def initialize(api_key)
        @api_key = api_key
      end

      # @param url [String]
      # @param payload [Hash]
      # @param signature [String]
      # @return [Boolean] whether signature valid or not.
      def validate(url, payload, signature)
        return false if signature.blank?

        signature == valid_signature(url, payload)
      end

      private

      # @param url [String]
      # @param payload [Hash,Array]
      # @return [String] generated signature in URL safe format.
      def valid_signature(url, payload)
        data = normalize_url(url) + normalize_payload(payload)
        OpenSSL::HMAC.hexdigest(DIGEST_ALGO, @api_key, data)
      end

      # @param payload [Hash,Array]
      # @return [String] normalized payload.
      def normalize_payload(payload)
        if payload.is_a?(Hash)
          payload.sort.join
        else
          payload.map { |item| item.sort.join }.join
        end
      end

      # @return [String] normalized URL.
      def normalize_url(url)
        parsed_url = URI ensure_protocol_url(url)
        url = "#{parsed_url.scheme || 'http'}://"
        url += "#{parsed_url.userinfo}@" if parsed_url.userinfo
        url += "#{parsed_url.host}:#{parsed_url.port || parsed_url.default_port}#{parsed_url.path}"
        url += "?#{parsed_url.query}" if parsed_url.query
        url += "##{parsed_url.fragment}" if parsed_url.fragment
        url
      end

      def ensure_protocol_url(url)
        if url[%r{\A[a-zA-Z]+://}i]
          url
        else
          'http://' + url
        end
      end
    end
  end
end
