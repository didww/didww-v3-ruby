# frozen_string_literal: true
#
# End-to-end SIP registration flow on /voice_in_trunks (API 2026-04-16):
# create with sip_registration enabled → rename → disable by setting
# `host` → re-enable by toggling the flag. The SDK keeps the
# dependent fields (`host`, `port`, `use_did_in_ruri`) aligned with
# the server's validation rules automatically. The sandbox trunk is
# left in place after the script completes so it can be inspected
# afterwards.
#
# Usage: DIDWW_API_KEY=your_sandbox_key ruby examples/voice_in_trunk_sip_registration.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

puts "=== Ruby SDK v#{DIDWW::VERSION} — SIP registration flow ==="

# 1) Create a SIP trunk with sip_registration enabled. The server
#    generates `incoming_auth_*` credentials and returns them in the
#    response — they are read-only and stripped from any subsequent
#    write payload by the SDK.
puts "\n[1/4] Create with sip_registration enabled..."
trunk = DIDWW::Client.voice_in_trunks.new(
  name: "sip-registration-example-#{Time.now.to_i}",
  priority: 1,
  weight: 100,
  cli_format: 'e164',
  ringing_timeout: 30,
  configuration: DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
    c.enabled_sip_registration = true
    c.use_did_in_ruri = true
    c.cnam_lookup = false
    c.codec_ids = [9, 7]
    c.transport_protocol_id = 1
  end
)
abort "create failed: #{trunk.errors.full_messages.join('; ')}" unless trunk.save
puts "  id=#{trunk.id}"
puts "  incoming_auth_username=#{trunk.configuration.incoming_auth_username.inspect}"
puts "  incoming_auth_password=#{trunk.configuration.incoming_auth_password.inspect}"
trunk_id = trunk.id

# 2) Rename — a single-field PATCH that doesn't touch SIP-registration state.
puts "\n[2/4] Rename trunk..."
trunk.name = "sip-registration-renamed-#{Time.now.to_i}"
abort "rename failed: #{trunk.errors.full_messages.join('; ')}" unless trunk.save
puts "  name=#{trunk.name}"

# 3) Disable sip_registration by setting `host`. The SDK flips
#    `enabled_sip_registration` and `use_did_in_ruri` to false in the
#    same PATCH so the server-side validators accept the change.
puts "\n[3/4] Disable by setting host..."
trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
  c.host = '203.0.113.10'
end
abort "disable failed: #{trunk.errors.full_messages.join('; ')}" unless trunk.save
fresh = DIDWW::Client.voice_in_trunks.find(trunk_id).first
puts "  enabled_sip_registration=#{fresh.configuration.enabled_sip_registration.inspect}"
puts "  use_did_in_ruri=#{fresh.configuration.use_did_in_ruri.inspect}"
puts "  host=#{fresh.configuration.host.inspect}"
puts "  incoming_auth_username=#{fresh.configuration.incoming_auth_username.inspect}"

# 4) Re-enable sip_registration. Setting `enabled_sip_registration = true`
#    sends host=nil / port=nil on the wire so the server (which still has
#    the host from step 3) is told to clear them.
puts "\n[4/4] Re-enable by toggling enabled_sip_registration..."
trunk = DIDWW::Client.voice_in_trunks.find(trunk_id).first
trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
  c.enabled_sip_registration = true
  c.use_did_in_ruri = true
end
abort "re-enable failed: #{trunk.errors.full_messages.join('; ')}" unless trunk.save
fresh = DIDWW::Client.voice_in_trunks.find(trunk_id).first
puts "  enabled_sip_registration=#{fresh.configuration.enabled_sip_registration.inspect}"
puts "  host=#{fresh.configuration.host.inspect}"
puts "  incoming_auth_username=#{fresh.configuration.incoming_auth_username.inspect}"

puts "\n=== PASS — trunk #{trunk_id} left in sandbox ==="
