module DIDWW
  module Resource
    class Did < Base
      has_one :trunk
      has_one :trunk_group
      has_one :capacity_pool
      has_one :shared_capacity_group

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

    end
  end
end
