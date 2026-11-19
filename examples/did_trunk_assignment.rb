# frozen_string_literal: true
# Demonstrates exclusive trunk/trunk group assignment on DIDs.
# Assigning a trunk auto-nullifies the trunk group and vice versa: the SDK sends
# the other relationship as null in the same PATCH.
# At the end the DID's original voice routing and description are restored and
# the created trunk and trunk group are deleted, also when a step fails.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_trunk_assignment.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

def print_did_assignment(did_id)
  result = DIDWW::Client.dids
           .includes(:voice_in_trunk, :voice_in_trunk_group)
           .find(did_id)
           .first
  puts "   trunk = #{result.voice_in_trunk&.id || 'null'}"
  puts "   group = #{result.voice_in_trunk_group&.id || 'null'}"
end

# Sends a PATCH with only the attributes and relationships set in the block
def update_did(did_id)
  did = DIDWW::Resource::Did.load(id: did_id)
  yield did
  raise "Error updating DID: #{did.errors.full_messages}" unless did.save
end

# Get a DID
puts '=== Finding DID ==='
did = DIDWW::Client.dids
      .includes(:voice_in_trunk, :voice_in_trunk_group)
      .page(1).per(1)
      .all
      .first
abort 'No DIDs found. Please order a DID first.' unless did
puts "Using DID: #{did.number} (#{did.id})"

# Remember the current routing and description to put them back at the end
original_trunk = did.voice_in_trunk
original_group = did.voice_in_trunk_group
original_description = did.description
puts "Current routing: trunk=#{original_trunk&.id || 'null'} group=#{original_group&.id || 'null'}"

suffix = SecureRandom.hex(4)
trunk = nil
trunk_group = nil
did_changed = false
begin
  # Create a trunk
  trunk = DIDWW::Client.voice_in_trunks.new(
    name: "Assignment Trunk #{suffix}",
    pop: DIDWW::Resource::VoiceInTrunk::POP_FRA, # optional; leave it nil to let DIDWW choose
    configuration: DIDWW::ComplexObject::SipConfiguration.new(
      host: 'sip.example.com',
      port: 5060,
      codecs: [
        DIDWW::ComplexObject::SipConfiguration::CODEC_PCMU,
        DIDWW::ComplexObject::SipConfiguration::CODEC_PCMA
      ],
      transport_protocol_id: 1 # UDP
    )
  )
  raise "Error creating trunk: #{trunk.errors.full_messages}" unless trunk.save
  puts "Created trunk: #{trunk.id}"

  # Create a trunk group
  trunk_group = DIDWW::Client.voice_in_trunk_groups.new(name: "Assignment Group #{suffix}", capacity_limit: 10)
  raise "Error creating trunk group: #{trunk_group.errors.full_messages}" unless trunk_group.save
  puts "Created trunk group: #{trunk_group.id}"

  # 1. Assign trunk to DID (auto-nullifies trunk group)
  did_changed = true
  update_did(did.id) { |d| d.voice_in_trunk = trunk }
  puts "\n1. Assigned trunk:"
  print_did_assignment(did.id)

  # 2. Assign trunk group to DID (auto-nullifies trunk)
  update_did(did.id) { |d| d.voice_in_trunk_group = trunk_group }
  puts "\n2. Assigned trunk group (the trunk is cleared):"
  print_did_assignment(did.id)

  # 3. Re-assign trunk (auto-nullifies trunk group again)
  update_did(did.id) { |d| d.voice_in_trunk = trunk }
  puts "\n3. Re-assigned trunk:"
  print_did_assignment(did.id)

  # 4. Update the description only: only changed fields are sent, so the trunk stays
  update_did(did.id) { |d| d.description = 'DID with trunk assigned' }
  puts "\n4. Updated description only (trunk stays):"
  print_did_assignment(did.id)
ensure
  # Restore the DID first, so the created trunk and group are no longer in use
  if did_changed
    update_did(did.id) do |d|
      if original_trunk
        d.voice_in_trunk = original_trunk
      elsif original_group
        d.voice_in_trunk_group = original_group
      else
        # nil unassigns only that relationship, so both are set
        d.voice_in_trunk = nil
        d.voice_in_trunk_group = nil
      end
      d.description = original_description
    end
    puts "\nRestored the DID's original routing:"
    print_did_assignment(did.id)
  end
  { 'trunk' => trunk, 'trunk group' => trunk_group }.each do |label, resource|
    next unless resource&.persisted?

    if resource.destroy
      puts "Deleted #{label} #{resource.id}"
    else
      puts "Error deleting #{label} #{resource.id}: #{resource.errors.full_messages}"
    end
  end
end
