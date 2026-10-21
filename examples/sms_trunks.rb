# frozen_string_literal: true
# CRUD for SMS trunks: lists trunks, creates an HTTP IN trunk, updates its
# configuration, and deletes it.
#
# Configuration types (DIDWW::ComplexObject::SmsTrunkConfiguration):
#   * sms_to_email, http_in — DIDWW delivers inbound messages by email or HTTP
#   * http_out, smpp_esme   — you connect to DIDWW; DIDWW generates the
#                             credentials, which are read-only
#   * smpp_smsc             — DIDWW binds to your SMSC
# The read-only allow_in / allow_out tell which directions a trunk handles.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/sms_trunks.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

configurations = DIDWW::ComplexObject::SmsTrunkConfiguration

puts '=== Existing SMS Trunks ==='
trunks = DIDWW::Client.sms_trunks
         .includes(:sms_trunk_group)
         .all

puts "Found #{trunks.size} SMS trunks"
trunks.first(10).each do |trunk|
  puts "#{trunk.name} [#{trunk.configuration&.type}]"
  puts "  ID: #{trunk.id}"
  puts "  Inbound: #{trunk.allow_in}, outbound: #{trunk.allow_out}"
  puts "  Group: #{trunk.sms_trunk_group.name}" if trunk.sms_trunk_group
  puts "  Submit URL: #{trunk.host}" if trunk.host
  puts ''
end

puts "\n=== Creating HTTP IN Trunk ==="
suffix = SecureRandom.hex(4)
trunk = DIDWW::Client.sms_trunks.new(
  name: "Ruby HTTP IN #{suffix}",
  external_reference_id: "ruby-sms-#{suffix}",
  configuration: configurations::HttpIn.new(
    url: 'https://example.com/sms',
    http_method: configurations::HttpIn::HTTP_METHOD_POST,
    body_type: configurations::HttpIn::BODY_TYPE_JSON,
    # Placeholders: {SMS_TEXT}, {SMS_TEXT_BASE64_ENCODED}, {SMS_SRC_ADDR}, {SMS_DST_ADDR}, {SMS_TIME}
    body: '{"text":"{SMS_TEXT}","from":"{SMS_SRC_ADDR}","to":"{SMS_DST_ADDR}"}',
    validate_https_certificate: true
  )
)

unless trunk.save
  abort "Error creating SMS trunk: #{trunk.errors.full_messages}"
end
puts "Created SMS trunk: #{trunk.id} - #{trunk.name}"
puts "  Configuration: #{trunk.configuration.type} -> #{trunk.configuration.url}"

begin
  # The configuration type cannot change; members left out keep their values.
  puts "\n=== Updating HTTP IN Trunk ==="
  trunk.name = "Ruby HTTP IN #{suffix} (v2)"
  trunk.configuration = configurations::HttpIn.new(url: 'https://example.com/sms/v2')
  if trunk.save
    puts "Updated: #{trunk.name} -> #{trunk.configuration.url}"
  else
    puts "Error updating SMS trunk: #{trunk.errors.full_messages}"
  end

  # The generated credentials of http_out and smpp_esme trunks are rotated with
  # regenerate_credentials and read back from the trunk:
  #
  # esme = DIDWW::Client.sms_trunks.find('smpp-esme-trunk-uuid').first
  # esme.regenerate_credentials
  # esme = DIDWW::Client.sms_trunks.find(esme.id).first
  # puts esme.configuration.system_id
ensure
  puts "\n=== Deleting SMS Trunk ==="
  puts trunk.destroy ? 'SMS trunk deleted' : "Error deleting SMS trunk: #{trunk.errors.full_messages}"
end

puts "\nConfiguration types: #{configurations::TYPES.join(', ')}"
