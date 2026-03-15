# frozen_string_literal: true
# Updates DID routing/capacity by assigning trunk and capacity pool.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/dids.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get the last ordered DID
puts '=== Finding last ordered DID ==='
dids = DIDWW::Client.dids
        .all

if dids.empty?
  puts 'No DIDs found. Please order a DID first.'
  exit 1
end

did = dids.first
puts "Selected DID: #{did.id}"

# Get last SIP trunk
puts "\n=== Finding SIP trunk ==="
trunks = DIDWW::Client.voice_in_trunks
          .where('configuration.type': 'sip_configurations')
          .all

if trunks.empty?
  puts 'No SIP trunks found. Please create a SIP trunk first.'
  exit 1
end

trunk = trunks.first
puts "Selected trunk: #{trunk.name}"

# Assign trunk to DID
puts "\n=== Assigning trunk to DID ==="
did.voice_in_trunk = trunk
updated_did = did.save
puts "Assigned trunk: #{did.voice_in_trunk.name if did.voice_in_trunk}"

# Assign capacity pool
puts "\n=== Assigning capacity pool ==="
capacity_pools = DIDWW::Client.capacity_pools.all

if !capacity_pools.empty?
  pool = capacity_pools.first
  did.capacity_pool = pool
  did.capacity_limit = 5
  did.description = 'Updated by Ruby example'
  did.save
  puts "DID #{did.id}"
  puts "  description: #{did.description}"
  puts "  capacity_limit: #{did.capacity_limit}"
else
  puts 'No capacity pools found'
end
