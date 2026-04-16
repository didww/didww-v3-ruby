# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module AuthenticationMethod
      # IpOnly is a read-only authentication method.
      # It can only be configured manually by DIDWW staff upon request
      # and cannot be set via the API on create or update.
      # Trunks with ip_only authentication can still be read and their
      # non-auth attributes updated via the API.
      class IpOnly < Base
        def self.type
          'ip_only'
        end

        property :allowed_sip_ips, type: :strings
        property :tech_prefix, type: :string
      end
    end
  end
end
