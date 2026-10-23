# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      # Outbound messages are submitted to DIDWW over HTTP. The submit URL is
      # returned in the trunk's meta as host.
      class HttpOut < Base
        def self.type
          'http_out'
        end

        property :callback_url, type: :string
        # Type: String
        # Nullable: Yes
        # Description: URL the status events of submitted messages are sent to

        property :allowed_ips, type: :strings
        # Type: Array of Strings
        # Nullable: Yes
        # Description: Addresses messages are accepted from

        property :auth_name, type: :string, read_only: true, sensitive: true
        # Type: String
        # Nullable: Yes
        # Description: Generated HTTP username

        property :auth_password, type: :string, read_only: true, sensitive: true
        # Type: String
        # Nullable: Yes
        # Description: Generated HTTP password
      end
    end
  end
end
