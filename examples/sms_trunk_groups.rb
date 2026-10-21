# frozen_string_literal: true
# CRUD for SMS trunk groups: creates two inbound trunks, puts them in a
# group, lists groups, and deletes the group.
#
# A group spreads a DID's inbound messages over its trunks by their
# priority (higher first). http_out trunks cannot join a group.
# Deleting a group also deletes the trunks in it.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/sms_trunk_groups.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

configurations = DIDWW::ComplexObject::SmsTrunkConfiguration
suffix = SecureRandom.hex(4)

puts '=== Creating SMS Trunks ==='
primary = DIDWW::Client.sms_trunks.new(
  name: "Ruby primary #{suffix}",
  priority: 200,
  configuration: configurations::HttpIn.new(
    url: 'https://example.com/sms',
    http_method: configurations::HttpIn::HTTP_METHOD_GET,
    query_parameters: { 'text' => '{SMS_TEXT}', 'from' => '{SMS_SRC_ADDR}' }
  )
)
fallback = DIDWW::Client.sms_trunks.new(
  name: "Ruby fallback #{suffix}",
  priority: 100,
  configuration: configurations::SmsToEmail.new(
    send_to: 'sms@example.com',
    subject: 'Inbound SMS',
    message: 'You have a new message.'
  )
)
[primary, fallback].each do |trunk|
  abort "Error creating SMS trunk: #{trunk.errors.full_messages}" unless trunk.save
  puts "Created SMS trunk: #{trunk.id} - #{trunk.name}"
end

puts "\n=== Creating SMS Trunk Group ==="
group = DIDWW::Client.sms_trunk_groups.new(
  name: "Ruby SMS Group #{suffix}",
  external_reference_id: "ruby-sms-group-#{suffix}"
)
group.relationships.sms_trunks = [primary, fallback]

if group.save
  puts "Created SMS trunk group: #{group.id} - #{group.name} (#{group.sms_trunks_count} trunks)"
else
  [primary, fallback].each(&:destroy)
  abort "Error creating SMS trunk group: #{group.errors.full_messages}"
end

puts "\n=== Existing SMS Trunk Groups ==="
groups = DIDWW::Client.sms_trunk_groups
         .includes(:sms_trunks)
         .all
groups.first(5).each do |g|
  names = g.sms_trunks ? g.sms_trunks.map(&:name).join(', ') : ''
  puts "#{g.name} (#{g.sms_trunks_count} trunks) #{names}"
end

puts "\n=== Deleting SMS Trunk Group (and its trunks) ==="
puts group.destroy ? 'SMS trunk group deleted' : "Error deleting SMS trunk group: #{group.errors.full_messages}"
