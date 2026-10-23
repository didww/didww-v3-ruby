# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      # DIDWW connects to the customer as an SMPP client.
      # host, system_id, password and server_location are required when the trunk is created.
      class SmppSmsc < Base
        def self.type
          'smpp_smsc'
        end

        property :host, type: :string
        # Type: String
        # Description: SMSC host DIDWW binds to

        property :tx_port, type: :integer
        # Type: Integer
        # Description: Transmitter port. Defaults to 2775.

        property :rx_port, type: :integer
        # Type: Integer
        # Description: Receiver port. Defaults to 2776.

        property :transceiver_mode, type: :boolean
        # Type: Boolean
        # Description: Bind as a transceiver instead of separate tx/rx

        property :connection_timeout, type: :integer
        # Type: Integer
        # Description: Bind timeout, seconds

        property :use_ssl, type: :boolean
        # Type: Boolean
        # Description: Wrap the connection in TLS

        property :system_id, type: :string
        # Type: String
        # Description: SMPP system_id DIDWW binds with, up to 15 characters

        property :system_type, type: :string
        # Type: String
        # Nullable: Yes
        # Description: SMPP system_type, up to 12 characters

        property :password, type: :string, sensitive: true
        # Type: String
        # Description: SMPP bind password, up to 8 characters

        property :server_location, type: :string
        # Type: String
        # Description: DIDWW SMPP server location, one of SERVER_LOCATIONS
      end
    end
  end
end
