# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module AuthenticationMethod
      class CredentialsAndIp < Base
        def self.type
          'credentials_and_ip'
        end

        # `username` and `password` are server-generated on create and returned
        # only in responses; they cannot be set from the client on create.
        property :allowed_sip_ips, type: :strings
        property :tech_prefix, type: :string
        property :username, type: :string, sensitive: true
        property :password, type: :string, sensitive: true
      end
    end
  end
end
