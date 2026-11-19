# frozen_string_literal: true
# Routes a DID's inbound SMS to an SMS trunk, then to an SMS trunk group.
# The two are exclusive: assigning one sends the other as null in the same
# PATCH, just like voice_in_trunk and voice_in_trunk_group. At the end the
# DID's original SMS routing is restored, also when a step fails.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_sms_routing.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

def print_sms_routing(did_id)
  result = DIDWW::Client.dids
           .includes(:sms_trunk, :sms_trunk_group)
           .find(did_id)
           .first
  puts "   sms_trunk       = #{result.sms_trunk&.id || 'null'}"
  puts "   sms_trunk_group = #{result.sms_trunk_group&.id || 'null'}"
end

# Sends a PATCH with only the relationships set in the block
def update_did(did_id)
  did = DIDWW::Resource::Did.load(id: did_id)
  yield did
  raise "Error updating DID: #{did.errors.full_messages}" unless did.save
end

puts '=== Finding DID ==='
did = DIDWW::Client.dids
      .includes(:sms_trunk, :sms_trunk_group)
      .page(1).per(1)
      .all
      .first
abort 'No DIDs found. Please order a DID first.' unless did
puts "Using DID: #{did.number} (#{did.id})"

puts "\n=== Finding inbound SMS trunk ==="
trunk = DIDWW::Client.sms_trunks.all.find(&:allow_in)
abort 'No inbound SMS trunk found. Run examples/sms_trunks.rb or create one first.' unless trunk
puts "Selected SMS trunk: #{trunk.name} (#{trunk.id})"

puts "\n=== Finding SMS trunk group ==="
group = DIDWW::Client.sms_trunk_groups.page(1).per(1).all.first
puts group ? "Selected SMS trunk group: #{group.name} (#{group.id})" : 'No SMS trunk group found; step 2 is skipped.'

# Remember the current routing to put it back at the end
original_trunk = did.sms_trunk
original_group = did.sms_trunk_group
puts "\nCurrent SMS routing:"
print_sms_routing(did.id)

did_changed = false
begin
  # 1. Assign the SMS trunk (sends sms_trunk_group as null)
  puts "\n=== 1. Assigning SMS trunk to DID ==="
  did_changed = true
  update_did(did.id) { |d| d.sms_trunk = trunk }
  print_sms_routing(did.id)

  puts "\n=== DIDs routed to #{trunk.name} ==="
  DIDWW::Client.dids.where('sms_trunk.id': trunk.id).all.each { |d| puts "   #{d.number}" }

  # 2. Assign the SMS trunk group (sends sms_trunk as null)
  if group
    puts "\n=== 2. Assigning SMS trunk group to DID (clears the SMS trunk) ==="
    update_did(did.id) { |d| d.sms_trunk_group = group }
    print_sms_routing(did.id)
  end
ensure
  if did_changed
    # 3. Restore the original routing. nil unassigns only that relationship,
    # so both are set to unroute the DID's inbound SMS.
    puts "\n=== 3. Restoring the DID's original SMS routing ==="
    update_did(did.id) do |d|
      if original_trunk
        d.sms_trunk = original_trunk
      elsif original_group
        d.sms_trunk_group = original_group
      else
        d.sms_trunk = nil
        d.sms_trunk_group = nil
      end
    end
    print_sms_routing(did.id)
  end
end
