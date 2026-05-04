# frozen_string_literal: true
# Lists voice in trunks and their configurations.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/voice_in_trunks.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List voice in trunks with included relationships
puts '=== Existing Trunks ==='
trunks = DIDWW::Client.voice_in_trunks
          .includes(:pop, :voice_in_trunk_group)
          .all

puts "Found #{trunks.size} trunks"
trunks.first(10).each do |trunk|
  config_type = trunk.configuration ? trunk.configuration.class.name.split('::').last : 'unknown'
  puts "#{trunk.name} [#{config_type}]"
  puts "  ID: #{trunk.id}"
  puts "  Priority: #{trunk.priority}"
  puts "  Weight: #{trunk.weight}"
  puts "  CLI Format: #{trunk.cli_format}"
  puts "  Ringing Timeout: #{trunk.ringing_timeout}"
  if trunk.pop
    puts "  POP: #{trunk.pop.name}"
  end
  puts ''
end

# Find a specific trunk by ID
if !trunks.empty?
  puts "\n=== Specific Trunk Details ==="
  specific_trunk = DIDWW::Client.voice_in_trunks.find(trunks.first.id).first
  puts "Trunk: #{specific_trunk.name}"
  puts "  ID: #{specific_trunk.id}"
  puts "  Description: #{specific_trunk.description}"
  puts "  Created at: #{specific_trunk.created_at}"
end

# 2026-04-16 — surface the API 2026-04-16 SIP-registration-related attributes when
# the trunk uses a SIP configuration. `incoming_auth_username` /
# `incoming_auth_password` are server-generated and only present when
# `enabled_sip_registration` is true.
sip_trunk = trunks.find { |t| t.configuration.is_a?(DIDWW::ComplexObject::SipConfiguration) }
if sip_trunk
  puts "\n=== SIP Configuration (2026-04-16 attributes) ==="
  config = sip_trunk.configuration
  puts "Trunk: #{sip_trunk.name}"
  puts "  enabled_sip_registration:  #{config.enabled_sip_registration.inspect}"
  puts "  use_did_in_ruri:           #{config.use_did_in_ruri.inspect}"
  puts "  network_protocol_priority: #{config.network_protocol_priority.inspect}"
  puts "  diversion_relay_policy:    #{config.diversion_relay_policy.inspect}"
  puts "  diversion_inject_mode:     #{config.diversion_inject_mode.inspect}"
  puts "  cnam_lookup:               #{config.cnam_lookup.inspect}"
  if config.enabled_sip_registration
    puts "  incoming_auth_username:    #{config.incoming_auth_username.inspect}"
    puts "  incoming_auth_password:    #{config.incoming_auth_password.inspect}"
  else
    puts '  (incoming_auth credentials only appear when SIP registration is enabled)'
  end
end

# Example: create a new SIP trunk with SIP registration enabled. The server
# generates `incoming_auth_username` / `incoming_auth_password` and returns
# them in the response. They are READ-ONLY — sending them on POST/PATCH
# returns 400 Param not allowed; the SDK strips them from write payloads.
#
# Server-side rules to keep in mind:
#   * When `enabled_sip_registration: true`, `host` and `port` MUST be left
#     blank (the server will register inbound and pick the host itself).
#   * When DISABLING SIP registration on an existing trunk, you must
#     simultaneously set `host` to a non-blank value and `use_did_in_ruri`
#     to `false` in the same PATCH — otherwise the server returns 422.
#
# Uncomment to actually create a trunk in your sandbox account:
#
# new_trunk = DIDWW::Resource::VoiceInTrunk.new(
#   name: "SIP-registration trunk #{Time.now.to_i}",
#   priority: 1,
#   weight: 100,
#   cli_format: 'e164',
#   ringing_timeout: 30,
#   configuration: DIDWW::ComplexObject::SipConfiguration.new(
#     # NOTE: do NOT set `host` here — the server requires it to be blank
#     # when enabled_sip_registration is true.
#     enabled_sip_registration: true,
#     use_did_in_ruri: true,
#     cnam_lookup: false,
#     diversion_relay_policy: 'as_is',
#     diversion_inject_mode: 'did_number',
#     network_protocol_priority: 'prefer_ipv4',
#     codec_ids: [9, 7],
#     transport_protocol_id: 1
#   )
# )
# created = new_trunk.save
# if created
#   puts "Created trunk #{new_trunk.id}"
#   puts "  incoming_auth_username: #{new_trunk.configuration.incoming_auth_username}"
#   puts "  incoming_auth_password: #{new_trunk.configuration.incoming_auth_password}"
# else
#   puts "Errors: #{new_trunk.errors.full_messages}"
# end
