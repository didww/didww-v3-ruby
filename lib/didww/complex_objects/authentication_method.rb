# frozen_string_literal: true
require 'didww/complex_objects/authentication_methods/base'
require 'didww/complex_objects/authentication_methods/ip_only'
require 'didww/complex_objects/authentication_methods/credentials_and_ip'
require 'didww/complex_objects/authentication_methods/twilio'

module DIDWW
  module ComplexObject
    module AuthenticationMethod
      TYPES = [
        IpOnly.type,
        CredentialsAndIp.type,
        Twilio.type
      ].freeze
    end
  end
end
