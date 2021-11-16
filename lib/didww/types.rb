# frozen_string_literal: true

require 'json_api_client/schema'
require 'didww/types/ip_addresses'
require 'didww/types/strings'
require 'didww/complex_objects/base'
require 'didww/complex_objects/export_filters'

JsonApiClient::Schema.register ip_addresses: DIDWW::Types::IpAddresses,
                               strings: DIDWW::Types::Strings,
                               complex_object: DIDWW::ComplexObject::Base,
                               export_filters: DIDWW::ComplexObject::ExportFilters
