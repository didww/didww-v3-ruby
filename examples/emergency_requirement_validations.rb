# frozen_string_literal: true
# Validates an emergency calling service order before placing it (2026-04-16).
#
# EmergencyRequirementValidation is a write-only endpoint: POST the
# intended (emergency_requirement, address, identity) triple and the server
# either returns 204 No Content (OK to order) or JSONAPI errors describing
# what the customer must fix (missing address fields, wrong identity type,
# unsupported area level, etc.).
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/emergency_requirement_validations.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Pick any emergency requirement + address + identity from your account.
requirement = DIDWW::Client.emergency_requirements.all.first
address     = DIDWW::Client.addresses.all.first
identity    = DIDWW::Client.identities.all.first

abort 'No emergency_requirements found on this account' unless requirement
abort 'No addresses found on this account'               unless address
abort 'No identities found on this account'              unless identity

puts 'Validating order setup with:'
puts "  Emergency Requirement: #{requirement.id}"
puts "  Address:               #{address.id}"
puts "  Identity:              #{identity.id}"

validation = DIDWW::Client.emergency_requirement_validations.new(
  emergency_requirement: requirement,
  address: address,
  identity: identity
)

if validation.save
  puts "\nValidation passed — this combination can be used to order emergency calling."
else
  puts "\nValidation failed:"
  validation.errors.full_messages.each { |msg| puts "  * #{msg}" }
end
