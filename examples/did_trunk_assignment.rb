# frozen_string_literal: true
# Demonstrates exclusive trunk/trunk group assignment on DIDs.
# Assigning a trunk auto-nullifies the trunk group and vice versa.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_trunk_assignment.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get a DID to work with
puts '=== Finding DID ==='
dids = DIDWW::Client.dids
       .includes(:voice_in_trunk, :voice_in_trunk_group)
       .all

if dids.empty?
  puts 'No DIDs found. Please order a DID first.'
  exit 1
end

did = dids.first
puts "Using DID: #{did.number} (#{did.id})"

# Get a trunk
puts "\n=== Finding Trunk ==="
trunks = DIDWW::Client.voice_in_trunks.all

if trunks.empty?
  puts 'No trunks found. Please create a trunk first.'
  exit 1
end

trunk = trunks.first
puts "Selected trunk: #{trunk.name} (#{trunk.id})"

# Get a trunk group
puts "\n=== Finding Trunk Group ==="
trunk_groups = DIDWW::Client.voice_in_trunk_groups.all

if trunk_groups.empty?
  puts 'No trunk groups found. Please create a trunk group first.'
  exit 1
end

trunk_group = trunk_groups.first
puts "Selected trunk group: #{trunk_group.name} (#{trunk_group.id})"

def print_did_assignment(client, did_id)
  result = client.dids
           .includes(:voice_in_trunk, :voice_in_trunk_group)
           .find(did_id)
           .first
  trunk = result.voice_in_trunk ? result.voice_in_trunk.id : 'null'
  group = result.voice_in_trunk_group ? result.voice_in_trunk_group.id : 'null'
  puts "   trunk = #{trunk}"
  puts "   group = #{group}"
end

begin
  # 1. Assign trunk to DID (auto-nullifies trunk group)
  puts "\n=== 1. Assigning trunk to DID ==="
  did.voice_in_trunk = trunk
  if did.save
    print_did_assignment(DIDWW::Client, did.id)
  else
    puts "Error assigning trunk: #{did.errors.full_messages}"
  end

  # 2. Assign trunk group to DID (auto-nullifies trunk)
  puts "\n=== 2. Assigning trunk group to DID ==="
  did_fresh = DIDWW::Client.dids.find(did.id).first
  did_fresh.voice_in_trunk_group = trunk_group
  if did_fresh.save
    print_did_assignment(DIDWW::Client, did.id)
  else
    puts "Error assigning trunk group: #{did_fresh.errors.full_messages}"
  end

  # 3. Re-assign trunk (auto-nullifies trunk group again)
  puts "\n=== 3. Re-assigning trunk ==="
  did_fresh = DIDWW::Client.dids.find(did.id).first
  did_fresh.voice_in_trunk = trunk
  if did_fresh.save
    print_did_assignment(DIDWW::Client, did.id)
  else
    puts "Error re-assigning trunk: #{did_fresh.errors.full_messages}"
  end

  # 4. Update description only (trunk stays assigned)
  puts "\n=== 4. Updating description only (trunk stays) ==="
  did_fresh = DIDWW::Client.dids.find(did.id).first
  did_fresh.description = 'DID with trunk assigned'
  if did_fresh.save
    print_did_assignment(DIDWW::Client, did.id)
  else
    puts "Error updating description: #{did_fresh.errors.full_messages}"
  end

  puts "\nDemonstration complete!"
rescue StandardError => e
  puts "Error: #{e.message}"
end
