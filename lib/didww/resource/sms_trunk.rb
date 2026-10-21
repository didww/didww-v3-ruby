# frozen_string_literal: true
require 'didww/complex_objects/sms_trunk_configuration'

module DIDWW
  module Resource
    # meta carries: host, the URL to submit outbound messages to (http_out trunks only).
    class SmsTrunk < Base
      has_many :outgoing_dids, class_name: 'Did'
      has_many :incoming_dids, class_name: 'Did'
      has_one :sms_trunk_group, class_name: 'SmsTrunkGroup'

      property :name, type: :string
      # Type: String
      # Description: Friendly name of the trunk. Required when the trunk is created.

      property :external_reference_id, type: :string
      # Type: String
      # Nullable: Yes
      # Description: Customer-supplied reference. Max 100 characters.

      property :blocked, type: :boolean
      # Type: Boolean
      # Description: Set to true to stop the trunk from handling messages

      property :priority, type: :integer
      # Type: Integer
      # Nullable: Yes
      # Description: Routing priority within an SMS trunk group, 0-32767; the higher value is tried first.
      #              Defaults to 100, and must stay null on http_out trunks, which cannot join a group.

      property :allow_any_did_as_source, type: :boolean
      # Type: Boolean
      # Description: Allow any DID the customer owns as the message source. Turning it on empties
      #              outgoing_dids. Refused on the trunk types that only receive messages.

      property :allow_in, type: :boolean
      # Type: Boolean
      # Description: True when the trunk handles inbound messages. Read-only.

      property :allow_out, type: :boolean
      # Type: Boolean
      # Description: True when the trunk can send messages. Read-only.

      property :created_at, type: :time
      # Type: DateTime
      # Description: Trunk created at DateTime. Read-only.

      property :updated_at, type: :time
      # Type: DateTime
      # Description: Trunk updated at DateTime. Read-only.

      property :configuration, type: :sms_trunk_configuration
      # Type: one of ComplexObject::SmsTrunkConfiguration::TYPES
      #   sms_to_email, http_in, http_out, smpp_esme, smpp_smsc
      # Description: Delivery configuration. Required when the trunk is created. On update the
      #              type must match the stored one; attributes left out keep their values.

      def initialize(*args)
        super
        attribute_will_change!(:configuration) if configuration
      end

      # The server sends meta on http_out trunks only.
      def host
        attributes[:meta]&.[](:host)
      end

      def regenerate_credentials
        resource = DIDWW::Resource::SmsTrunkRegenerateCredential.new
        resource.relationships[:sms_trunk] = self
        resource.save
      end
    end
  end
end
