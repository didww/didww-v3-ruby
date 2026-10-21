# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      # The customer connects to DIDWW as an SMPP ESME.
      class SmppEsme < Base
        def self.type
          'smpp_esme'
        end

        property :system_type, type: :string
        # Type: String
        # Nullable: Yes
        # Description: SMPP system_type, up to 12 characters

        property :allowed_ips, type: :strings
        # Type: Array of Strings
        # Nullable: Yes
        # Description: Addresses the ESME may bind from

        property :server_location, type: :string
        # Type: String
        # Description: DIDWW SMPP server location, one of SERVER_LOCATIONS. Required when
        #              the trunk is created.

        property :system_id, type: :string, read_only: true, sensitive: true
        # Type: String
        # Description: Generated SMPP system_id to bind with

        property :password, type: :string, read_only: true, sensitive: true
        # Type: String
        # Description: Generated SMPP bind password
      end
    end
  end
end
