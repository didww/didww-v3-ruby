# frozen_string_literal: true
# Lists identities, addresses, and proofs. Demonstrates compliance workflow.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/identities_and_proofs.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List identities
puts '=== Identities ==='
identities = DIDWW::Client.identities.all
puts "Found #{identities.size} identities"

identities.first(10).each do |identity|
  puts "\nIdentity: #{identity.id}"
  puts "  Name: #{identity.first_name} #{identity.last_name}"
  puts "  Phone: #{identity.phone_number}"
  puts "  Type: #{identity.identity_type}"
  puts "  Verified: #{identity.verified}"
  puts "  Created: #{identity.created_at}"
end

# List addresses
puts "\n=== Addresses ==="
addresses = DIDWW::Client.addresses
            .includes(:identity)
            .all

puts "Found #{addresses.size} addresses"

addresses.first(10).each do |address|
  puts "\nAddress: #{address.id}"
  puts "  Street: #{address.address}"
  puts "  City: #{address.city_name}"
  puts "  Postal Code: #{address.postal_code}"
  puts "  Verified: #{address.verified}"
  if address.identity
    puts "  Identity: #{address.identity.first_name} #{address.identity.last_name}"
  end
end

# List proof types
puts "\n=== Proof Types ==="
proof_types = DIDWW::Client.proof_types.all
puts "Found #{proof_types.size} proof types"

proof_types.first(10).each do |pt|
  puts "#{pt.name} (#{pt.entity_type})"
end

puts "\n=== Identities and Proofs Workflow ==="
puts '1. Create an identity with personal information'
puts '2. Create an address linked to the identity'
puts '3. Encrypt and upload identity/address documents'
puts '4. Create proofs attached to identity/address with uploaded files'
puts '5. Monitor verification status'
puts "\nNote: Creating and uploading encrypted files requires additional SDK setup."
