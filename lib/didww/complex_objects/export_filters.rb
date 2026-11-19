# frozen_string_literal: true
require 'json_api_client/schema'

module DIDWW
  module ComplexObject
    class ExportFilters < Base
      # Allowed values for trunk_type (sms_in only)
      TRUNK_TYPE_SMPP_SMSC = 'smpp_smsc'
      TRUNK_TYPE_SMPP_ESME = 'smpp_esme'
      TRUNK_TYPE_SMS_TO_EMAIL = 'sms_to_email'
      TRUNK_TYPE_HTTP_IN = 'http_in'

      TRUNK_TYPES = [
        TRUNK_TYPE_SMPP_SMSC,
        TRUNK_TYPE_SMPP_ESME,
        TRUNK_TYPE_SMS_TO_EMAIL,
        TRUNK_TYPE_HTTP_IN
      ].freeze

      # Allowed values for service_type (sms_out only)
      SERVICE_TYPE_A2P = 'a2p'
      SERVICE_TYPE_P2P = 'p2p'

      SERVICE_TYPES = [
        SERVICE_TYPE_A2P,
        SERVICE_TYPE_P2P
      ].freeze

      # Ruby-friendly property names for the dotted keys on the wire
      DOTTED_KEYS = {
        'voice_out_trunk_id' => 'voice_out_trunk.id',
        'sms_trunk_id' => 'sms_trunk.id',
        'sender_id_verification_id' => 'sender_id_verification.id'
      }.freeze

      # Type casting for JsonApiClient parser/setters
      def self.cast_single_object(hash)
        new(hash)
      end

      # Every export type
      property :from,       type: :string # "YYYY-MM-DD HH:MM:SS" UTC lower bound, INCLUSIVE (time_start >= from). Required.
      property :to,         type: :string # "YYYY-MM-DD HH:MM:SS" UTC upper bound, EXCLUSIVE (time_start <  to). Required.

      # cdr_in
      property :did_number, type: :string
      property :source_number, type: :string
      property :source_number_out, type: :string
      property :source_country_iso, type: :string

      # cdr_out
      property :voice_out_trunk_id, type: :string # sent as voice_out_trunk.id
      property :source, type: :string
      property :cli, type: :string
      property :destination, type: :string

      # sms_in and sms_out
      property :source_address_eq, type: :string
      property :source_address_cont, type: :string
      property :destination_address_eq, type: :string
      property :destination_address_cont, type: :string
      # sms_in: success, failed, queued; sms_out: routing_error, in_progress, queued, failed, success
      property :status, type: :string
      property :sms_trunk_id # String or Array of Strings, sent as sms_trunk.id
      property :sms_id, type: :string

      # sms_in only
      property :trunk_type # String or Array of Strings from TRUNK_TYPES

      # sms_out only
      property :service_type, type: :string # one of SERVICE_TYPES, lowercase
      property :sender_id_verification_id # String or Array of Strings, sent as sender_id_verification.id

      # Returned on exports created at earlier API versions only
      property :year, type: :string, read_only: true
      property :month, type: :string, read_only: true
      property :day, type: :string, read_only: true

      def initialize(params = {})
        super(params.to_h.transform_keys { |key| DOTTED_KEYS.key(key.to_s) || key })
      end

      def as_json(*)
        result = attributes.as_json.with_indifferent_access
        DOTTED_KEYS.each { |name, wire_key| result[wire_key] = result.delete(name) if result.key?(name) }
        result.except(*self.class.read_only_attributes)
      end

    end
  end
end
