# frozen_string_literal: true
# Voice IN trunks: lists trunks with their configurations, finds one, creates a
# SIP trunk and a PSTN trunk, updates both and deletes both.
#
# The configuration type of a trunk cannot change; a configuration sent on
# update replaces the members it carries. SIP registration has its own example,
# voice_in_trunk_sip_registration.rb.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/trunks.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

sip_class = DIDWW::ComplexObject::SipConfiguration
suffix = SecureRandom.hex(4)

# List voice in trunks with included relationships
puts '=== Existing Trunks ==='
trunks = DIDWW::Client.voice_in_trunks
         .includes(:voice_in_trunk_group)
         .page(1).per(10)
         .all

puts "Found #{trunks.size} trunks"
trunks.each do |trunk|
  puts "#{trunk.name} [#{trunk.configuration_type_human}]"
  puts "  ID: #{trunk.id}"
  puts "  Priority / weight: #{trunk.priority} / #{trunk.weight}"
  puts "  CLI format: #{trunk.cli_format}"
  puts "  Ringing timeout: #{trunk.ringing_timeout}"
  puts "  POP: #{trunk.pop || 'chosen by DIDWW'}"
  puts "  Trunk group: #{trunk.voice_in_trunk_group.name}" if trunk.voice_in_trunk_group
  config = trunk.configuration
  if config.is_a?(sip_class)
    # Codec names in priority order, the first is the highest
    puts "  Codecs: #{Array(config.codecs).join(', ')}"
    puts "  ICE / RTCP mux / RTCP feedback: #{config.ice_mode} / #{config.rtcp_mux_mode} / #{config.rtcp_feedback_mode}"
    puts "  SIP registration: #{config.enabled_sip_registration.inspect}"
  elsif config.is_a?(DIDWW::ComplexObject::PstnConfiguration)
    puts "  Forwards to: #{config.dst}"
  end
end

# Find a specific trunk by ID
unless trunks.empty?
  puts "\n=== Specific Trunk ==="
  found = DIDWW::Client.voice_in_trunks.find(trunks.first.id).first
  puts "#{found.name} (#{found.id}), created at #{found.created_at}"
end

# Create a SIP trunk
puts "\n=== Creating SIP Trunk ==="
sip_trunk = DIDWW::Client.voice_in_trunks.new(
  name: "Ruby SIP Trunk #{suffix}",
  priority: 1,
  weight: 100,
  cli_format: DIDWW::Resource::VoiceInTrunk::CLI_FORMAT_E164,
  ringing_timeout: 30,
  capacity_limit: 10,
  pop: DIDWW::Resource::VoiceInTrunk::POP_FRA, # optional; leave it nil to let DIDWW choose
  configuration: sip_class.new(
    username: sip_class::DID_PLACEHOLDER, # the dialed DID is sent as the R-URI user
    host: 'sip.example.com',
    port: 5060,
    # Codecs by name, in priority order; left out, DIDWW applies its default list
    codecs: [sip_class::CODEC_PCMU, sip_class::CODEC_PCMA, sip_class::CODEC_TELEPHONE_EVENT],
    ice_mode: sip_class::ICE_MODE_ACCEPT,
    transport_protocol_id: 1, # UDP, see sip_class::TRANSPORT_PROTOCOLS
    rerouting_disconnect_code_ids: [84, 100] # 480 Temporarily Unavailable, 503 Service Unavailable
  )
)
abort "Error creating SIP trunk: #{sip_trunk.errors.full_messages}" unless sip_trunk.save
puts "Created SIP trunk: #{sip_trunk.id} - #{sip_trunk.name} (pop #{sip_trunk.pop})"

pstn_trunk = nil
begin
  # Update the SIP trunk: only the changed attributes are sent
  puts "\n=== Updating SIP Trunk ==="
  sip_trunk.description = 'Updated by Ruby example'
  sip_trunk.ringing_timeout = 45
  sip_trunk.configuration = sip_class.new(codecs: [sip_class::CODEC_PCMA, sip_class::CODEC_TELEPHONE_EVENT])
  abort "Error updating SIP trunk: #{sip_trunk.errors.full_messages}" unless sip_trunk.save
  puts "Updated SIP trunk: #{sip_trunk.description}, ringing timeout #{sip_trunk.ringing_timeout}"
  puts "  Codecs: #{Array(sip_trunk.configuration.codecs).join(', ')}"

  # Create a PSTN trunk: calls are forwarded to a phone number
  puts "\n=== Creating PSTN Trunk ==="
  pstn_trunk = DIDWW::Client.voice_in_trunks.new(
    name: "Ruby PSTN Trunk #{suffix}",
    ringing_timeout: 30,
    configuration: DIDWW::ComplexObject::PstnConfiguration.new(dst: '12125551234')
  )
  abort "Error creating PSTN trunk: #{pstn_trunk.errors.full_messages}" unless pstn_trunk.save
  puts "Created PSTN trunk: #{pstn_trunk.id} - #{pstn_trunk.name}"
  puts "  Config type: #{pstn_trunk.configuration.type}"
  puts "  DST: #{pstn_trunk.configuration.dst}"

  # Update the PSTN trunk: rename it and forward to another number
  puts "\n=== Updating PSTN Trunk ==="
  pstn_trunk.name = "Ruby PSTN Trunk #{suffix} (v2)"
  pstn_trunk.configuration = DIDWW::ComplexObject::PstnConfiguration.new(dst: '12125550000')
  abort "Error updating PSTN trunk: #{pstn_trunk.errors.full_messages}" unless pstn_trunk.save
  puts "Updated PSTN trunk: #{pstn_trunk.name} -> #{pstn_trunk.configuration.dst}"
ensure
  puts "\n=== Deleting Trunks ==="
  [sip_trunk, pstn_trunk].compact.select(&:persisted?).each do |trunk|
    puts trunk.destroy ? "Deleted trunk #{trunk.id}" : "Error deleting trunk #{trunk.id}: #{trunk.errors.full_messages}"
  end
end
