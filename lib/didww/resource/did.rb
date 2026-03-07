# frozen_string_literal: true
module DIDWW
  module Resource
    class Did < Base
      has_one :did_group
      has_one :order
      has_one :voice_in_trunk
      has_one :voice_in_trunk_group
      has_one :capacity_pool
      has_one :shared_capacity_group
      has_one :address_verification

      property :blocked, type: :boolean
      # Type: Boolean
      # Description: Identifier for a blocked DID. Blocked DIDs are numbers that have expired, have been cancelled or have been suspended by DIDWW.

      property :awaiting_registration, type: :boolean
      # Type: Boolean
      # Description: Identifier for a DID that is awaiting registration.

      property :terminated, type: :boolean
      # Type: Boolean
      # Description: Identifier for terminated DIDs that will be removed from service at the end of the billing cycle.

      property :billing_cycles_count, type: :integer
      # Type: Boolean
      # Description: Identifier for DIDs that are pending removal from your account.

      property :description, type: :string
      # Type: String
      # Description: DID custom description

      property :number, type: :string
      # Type: String
      # Description: The actual DID number in the format [country code][area code][subscriber number].

      property :capacity_limit, type: :integer
      # Type: Integer
      # Description: The capacity limit (maximum number of simultaneous calls) for this DID.

      property :channels_included_count, type: :integer
      # Type: Integer
      # Description: The number of channels included with this DID.

      property :dedicated_channels_count, type: :integer
      # Type: Integer
      # Description: The number of channels included with this DID.

      property :expires_at, type: :time
      # Type: DateTime
      # Description: DateTime when the DID expired or will expire. DateTime is in the ISO 8601 format "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", where "SSS" are milliseconds and 'Z' denotes Zulu time (UTC).

      property :created_at, type: :time
      # Type: DateTime
      # Description: DID created at DateTime

      EXCLUSIVE_RELATIONSHIPS = {
        'voice_in_trunk' => 'voice_in_trunk_group',
        'voice_in_trunk_group' => 'voice_in_trunk',
      }.freeze

      class ExclusiveRelations < JsonApiClient::Relationships::Relations
        def initialize(record_class, relations)
          @_initializing = true
          super
          @_initializing = false
        end

        def set_attribute(name, value)
          super
          return if @_initializing
          exclusive = Did::EXCLUSIVE_RELATIONSHIPS[name.to_s]
          if exclusive && !value.nil?
            super(exclusive, nil)
          end
        end
      end

      def relationships
        @relationships ||= ExclusiveRelations.new(self.class, {})
      end

      def relationships=(rels)
        attrs = case rels
                when JsonApiClient::Relationships::Relations then rels.attributes
                when Hash then rels
                else rels || {}
                end
        @relationships = ExclusiveRelations.new(self.class, attrs)
      end

    end
  end
end
