# frozen_string_literal: true
module DIDWW
  module Auth
    class Token
      ATTRIBUTES = %w[
        access_token
        token_type
        expires_in
        aud
        scope
        api_version
        minted_at
      ].freeze

      attr_reader(*ATTRIBUTES)

      # @param hash [Hash] Token response body or a hash produced by #to_h
      # @return [DIDWW::Auth::Token]
      def self.from_h(hash)
        attributes = hash.transform_keys(&:to_s).slice(*ATTRIBUTES)
        new(**attributes.transform_keys(&:to_sym))
      end

      def initialize(access_token: nil, token_type: nil, expires_in: nil, aud: nil, scope: nil, api_version: nil, minted_at: nil)
        @access_token = access_token
        @token_type = token_type
        @expires_in = expires_in
        @aud = Array(aud)
        @scope = scope
        @api_version = api_version
        @minted_at = minted_at
      end

      # String keys, so stores that serialize to JSON round-trip it.
      # @return [Hash]
      def to_h
        ATTRIBUTES.to_h { |name| [name, public_send(name)] }
      end

      def inspect
        "#<#{self.class.name} aud=#{aud.inspect} scope=#{scope.inspect} api_version=#{api_version.inspect} expires_in=#{expires_in.inspect}>"
      end
    end
  end
end
