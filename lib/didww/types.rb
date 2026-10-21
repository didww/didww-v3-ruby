# frozen_string_literal: true

require 'json_api_client/schema'
require 'didww/types/ip_addresses'
require 'didww/types/strings'
require 'didww/complex_objects/base'
require 'didww/complex_objects/export_filters'
require 'didww/complex_objects/authentication_method'
require 'didww/complex_objects/sms_trunk_configuration'

JsonApiClient::Schema.register ip_addresses: DIDWW::Types::IpAddresses,
                               strings: DIDWW::Types::Strings,
                               complex_object: DIDWW::ComplexObject::Base,
                               export_filters: DIDWW::ComplexObject::ExportFilters,
                               authentication_method: DIDWW::ComplexObject::AuthenticationMethod::Base,
                               sms_trunk_configuration: DIDWW::ComplexObject::SmsTrunkConfiguration::Base
