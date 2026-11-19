# frozen_string_literal: true
# Voice IN trunk groups: creates two SIP trunks and a trunk group with them,
# lists groups with their trunks, renames the group, and deletes the group and
# the trunks, also when a step fails.
#
# Deleting a group also deletes the trunks in it.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/voice_in_trunk_groups.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

sip_class = DIDWW::ComplexObject::SipConfiguration
suffix = SecureRandom.hex(4)

trunks = []
group = nil
begin
  # Create two trunks
  puts '=== Creating Trunks ==='
  [
    ['A', 'sip-a.example.com', [sip_class::CODEC_PCMU, sip_class::CODEC_PCMA]],
    ['B', 'sip-b.example.com', [sip_class::CODEC_PCMU]]
  ].each do |label, host, codecs|
    trunk = DIDWW::Client.voice_in_trunks.new(
      name: "Group Trunk #{label} #{suffix}",
      configuration: sip_class.new(host: host, port: 5060, codecs: codecs, transport_protocol_id: 1) # UDP
    )
    raise "Error creating trunk #{label}: #{trunk.errors.full_messages}" unless trunk.save
    trunks << trunk
    puts "Created trunk #{label}: #{trunk.id}"
  end

  # Create a trunk group with both trunks (2026-04-16 external_reference_id for customer tagging)
  puts "\n=== Creating Trunk Group ==="
  group = DIDWW::Client.voice_in_trunk_groups.new(
    name: "Ruby Trunk Group #{suffix}",
    capacity_limit: 10,
    external_reference_id: "ruby-tg-#{suffix}"
  )
  group.voice_in_trunks = trunks
  raise "Error creating trunk group: #{group.errors.full_messages}" unless group.save
  puts "Created trunk group: #{group.id} - #{group.name}"

  # List trunk groups with included trunks
  puts "\n=== Trunk Groups ==="
  groups = DIDWW::Client.voice_in_trunk_groups
           .includes(:voice_in_trunks)
           .all
  puts "Found #{groups.size} trunk groups"
  groups.each do |g|
    names = (g.voice_in_trunks || []).map(&:name)
    puts "  #{g.name} (#{names.size} trunks: #{names.join(', ')}) external_reference_id=#{g.external_reference_id}"
  end

  # Rename the group: only the name is sent
  puts "\n=== Updating Trunk Group ==="
  group.name = "Updated Group #{suffix}"
  raise "Error updating trunk group: #{group.errors.full_messages}" unless group.save
  puts "Updated name: #{group.name}"
ensure
  puts "\n=== Cleaning Up ==="
  if group&.persisted?
    # Deleting the group also deletes its trunks
    puts group.destroy ? 'Deleted trunk group (and its trunks)' : "Error deleting trunk group: #{group.errors.full_messages}"
  else
    # Without a group the trunks are deleted one by one
    trunks.each { |trunk| puts "Deleted trunk #{trunk.id}" if trunk.destroy }
  end
end
