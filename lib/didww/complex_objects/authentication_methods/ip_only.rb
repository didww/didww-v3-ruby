# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module AuthenticationMethod
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
