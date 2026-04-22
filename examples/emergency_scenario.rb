# frozen_string_literal: true
# End-to-end emergency calling service scenario (2026-04-16).
#
# This example walks through the full flow of purchasing an Emergency
# Calling Service:
#
#   1. Find a DID with the emergency feature that is not yet emergency-enabled.
#   2. Look up emergency requirements for that DID's country + did_group_type.
#   3. Find an existing identity on the account.
#   4. Find an existing address for that identity.
#   5. Validate the (emergency_requirement, address, identity) triple.
#   6. Create an emergency verification with the address and DID.
#   7. Fetch the created verification to confirm its status.
#   8. Fetch the auto-created emergency_calling_service via the verification.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/emergency_scenario.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# === Step 0: Order a specific available DID with emergency feature ===
puts '=== Step 0: Order an available DID with emergency feature ==='
# Find an address first so we know what country to order in
addresses = DIDWW::Client.addresses.includes(:country).all
abort 'No addresses on this account. Please create an address first.' if addresses.empty?
address_for_order = addresses.first
address_country = address_for_order.country
puts "  Using address country: #{address_country&.name} (#{address_country&.id})"

# Find an available DID with emergency feature in that country
available_dids = DIDWW::Client.available_dids
                  .where('did_group.features': 'emergency', 'country.id': address_country.id)
                  .includes(:did_group, 'did_group.stock_keeping_units')
                  .page(1).per(1)
                  .all

abort 'No available DIDs with emergency feature in this country.' if available_dids.empty?

available_did = available_dids.first
did_group = available_did.did_group
sku = did_group.stock_keeping_units.first
abort 'No SKU found for this DID group.' unless sku

puts "  Available DID: #{available_did.number}"
puts "  DID Group: #{did_group.area_name}"

item = DIDWW::ComplexObject::DidOrderItem.new(available_did_id: available_did.id, sku_id: sku.id)
order = DIDWW::Client.orders.new(items: [item])
abort "Failed to order DID: #{order.errors.full_messages}" unless order.save

puts "  Order: #{order.id} — #{order.status}"

# Wait for order to complete
10.times do
  break if order.status == 'completed'
  sleep 5
  order = DIDWW::Client.orders.find(order.id).first
end
abort "  Order did not complete (status: #{order.status})." unless order.status == 'completed'
puts '  Order completed'

# === Step 1: Find the newly ordered DID ===
puts "\n=== Step 1: Find the newly ordered DID ==="
dids = DIDWW::Client.dids
        .where('did_group.features': 'emergency', emergency_enabled: false)
        .includes(:did_group, 'did_group.country', 'did_group.did_group_type', :emergency_calling_service)
        .order('-created_at')
        .page(1).per(10)
        .all

# Pick a DID that is not yet assigned to an ECS
did = dids.find { |d| d.emergency_calling_service.nil? }
abort 'No available DID without an existing Emergency Calling Service.' unless did

did_group = did.did_group
country   = did_group.country
dgt       = did_group.did_group_type

puts "  DID:            #{did.number} (#{did.id})"
puts "  DID Group:      #{did_group.id}"
puts "  Country:        #{country&.name} (#{country&.id})"
puts "  DID Group Type: #{dgt&.name} (#{dgt&.id})"

# === Step 2: Get emergency requirements ===
puts "\n=== Step 2: Get emergency requirements for country + did_group_type ==="
requirements = DIDWW::Client.emergency_requirements
                .where('country.id': country.id, 'did_group_type.id': dgt.id)
                .all

requirement = requirements.first
abort "No emergency requirements found for country #{country.name} / #{dgt.name}." unless requirement

puts "  Emergency Requirement: #{requirement.id}"
puts "  Identity type:         #{requirement.identity_type}"
puts "  Address area level:    #{requirement.address_area_level}"
puts "  Estimated setup (days): #{requirement.estimate_setup_time}"
if requirement.meta
  puts "  Setup price:   #{requirement.meta[:setup_price]}"   if requirement.meta[:setup_price]
  puts "  Monthly price: #{requirement.meta[:monthly_price]}" if requirement.meta[:monthly_price]
end

# === Step 3: Find an existing identity ===
puts "\n=== Step 3: Find an existing identity ==="
identities = DIDWW::Client.identities.all
identity   = identities.first
abort 'No identities found on this account. Please create an identity first.' unless identity

puts "  Identity: #{identity.id}"
puts "  Type:     #{identity.identity_type}"

# === Step 4: Find an existing address ===
puts "\n=== Step 4: Find an existing address ==="
addresses = DIDWW::Client.addresses.all
address   = addresses.first
abort 'No addresses found on this account. Please create an address first.' unless address

puts "  Address: #{address.id}"

# === Step 5: Validate the order setup ===
puts "\n=== Step 5: Validate emergency requirement (requirement + address + identity) ==="
validation = DIDWW::Client.emergency_requirement_validation.new(
  relationships: {
    emergency_requirement: requirement,
    address: address,
    identity: identity
  }
)

if validation.save
  puts '  Validation passed -- this combination can be used for emergency calling.'
else
  puts '  Validation failed:'
  validation.errors.full_messages.each { |msg| puts "    * #{msg}" }
  abort 'Cannot proceed without a valid requirement/address/identity combination.'
end

# === Step 6: Create an emergency verification ===
puts "\n=== Step 6: Create emergency verification ==="
suffix = SecureRandom.hex(4)
verification = DIDWW::Client.emergency_verifications.new(
  callback_url: 'https://example.com/webhooks/emergency',
  callback_method: 'post',
  external_reference_id: "ruby-scenario-#{suffix}",
  relationships: {
    address: address,
    dids: [did]
  }
)

if verification.save
  puts "  Created verification: #{verification.id}"
  puts "  Reference:            #{verification.reference}"
  puts "  Status:               #{verification.status}"
  puts "  External Reference:   #{verification.external_reference_id}"
else
  puts '  Error creating verification:'
  verification.errors.full_messages.each { |msg| puts "    * #{msg}" }
  abort 'Failed to create emergency verification.'
end

# === Step 7: Fetch the verification to confirm status ===
puts "\n=== Step 7: Fetch the created verification ==="
fetched = DIDWW::Client.emergency_verifications
            .includes(:address, :emergency_calling_service, :dids)
            .find(verification.id)
            .first

puts "  Verification: #{fetched.id}"
puts "  Status:       #{fetched.status}"
puts "  DIDs:         #{fetched.dids.map(&:number).join(', ')}" if fetched.dids&.any?
puts "  Address:      #{fetched.address&.id}"

# === Step 8: Fetch the auto-created emergency_calling_service ===
puts "\n=== Step 8: Fetch emergency calling service ==="
ecs = fetched.emergency_calling_service
if ecs
  # Re-fetch with includes for full details
  service = DIDWW::Client.emergency_calling_services
              .includes(:country, :did_group_type, :dids)
              .find(ecs.id)
              .first

  puts "  Service:        #{service.id}"
  puts "  Name:           #{service.name}"
  puts "  Reference:      #{service.reference}"
  puts "  Status:         #{service.status}"
  puts "  Country:        #{service.country&.name}"
  puts "  DID Group Type: #{service.did_group_type&.name}"
  puts "  Attached DIDs:  #{service.dids.map(&:number).join(', ')}" if service.dids&.any?
  if service.meta
    puts "  Setup price:    #{service.meta[:setup_price]}"   if service.meta[:setup_price]
    puts "  Monthly price:  #{service.meta[:monthly_price]}" if service.meta[:monthly_price]
  end
else
  puts '  No emergency_calling_service linked yet (may be created asynchronously).'
end

puts "\nDone! Emergency calling service flow completed."
