# frozen_string_literal: true
# Routes a DID's inbound SMS to an SMS trunk, then to an SMS trunk group.
# The two are exclusive: assigning one sends the other as null in the same
# PATCH, just like voice_in_trunk and voice_in_trunk_group.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_sms_routing.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

puts '=== Finding DID ==='
did = DIDWW::Client.dids.all.first
abort 'No DIDs found. Please order a DID first.' unless did
puts "Using DID: #{did.number} (#{did.id})"

puts "\n=== Finding inbound SMS trunk ==="
trunk = DIDWW::Client.sms_trunks.all.find(&:allow_in)
abort 'No inbound SMS trunk found. Run examples/sms_trunks.rb or create one first.' unless trunk
puts "Selected SMS trunk: #{trunk.name} (#{trunk.id})"

puts "\n=== Finding SMS trunk group ==="
group = DIDWW::Client.sms_trunk_groups.all.first
puts group ? "Selected SMS trunk group: #{group.name} (#{group.id})" : 'No SMS trunk group found; step 2 is skipped.'

def print_sms_routing(did_id)
  result = DIDWW::Client.dids
           .includes(:sms_trunk, :sms_trunk_group)
           .find(did_id)
           .first
  puts "   sms_trunk       = #{result.sms_trunk&.id || 'null'}"
  puts "   sms_trunk_group = #{result.sms_trunk_group&.id || 'null'}"
end

begin
  puts "\n=== 1. Assigning SMS trunk to DID ==="
  did.sms_trunk = trunk
  if did.save
    print_sms_routing(did.id)
  else
    puts "Error assigning SMS trunk: #{did.errors.full_messages}"
  end

  if group
    puts "\n=== 2. Assigning SMS trunk group to DID (clears the SMS trunk) ==="
    did_fresh = DIDWW::Client.dids.find(did.id).first
    did_fresh.sms_trunk_group = group
    if did_fresh.save
      print_sms_routing(did.id)
    else
      puts "Error assigning SMS trunk group: #{did_fresh.errors.full_messages}"
    end
  end

  puts "\n=== DIDs routed to #{trunk.name} ==="
  DIDWW::Client.dids.where('sms_trunk.id': trunk.id).all.each { |d| puts "   #{d.number}" }
rescue StandardError => e
  puts "Error: #{e.message}"
end
