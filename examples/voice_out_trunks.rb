# frozen_string_literal: true
# CRUD for voice out trunks using 2026-04-16 polymorphic authentication_method.
# Note: Voice Out Trunks require additional account configuration.
# Contact DIDWW support to enable.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/voice_out_trunks.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List existing voice out trunks
puts '=== Existing Voice Out Trunks ==='
trunks = DIDWW::Client.voice_out_trunks.all
puts "Found #{trunks.size} voice out trunks"

trunks.first(5).each do |trunk|
  puts "#{trunk.name} (#{trunk.status})"
  puts "  ID: #{trunk.id}"
  auth = trunk.authentication_method
  puts "  Auth type: #{auth&.type}"
  case auth
  when DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp
    puts "  Username: #{auth.username}"
  when DIDWW::ComplexObject::AuthenticationMethod::IpOnly
    puts "  Allowed SIP IPs: #{auth.allowed_sip_ips}"
  when DIDWW::ComplexObject::AuthenticationMethod::Twilio
    puts "  Twilio Account SID: #{auth.twilio_account_sid}"
  end
  puts "  Default DST Action: #{trunk.default_dst_action}"
  puts "  On CLI Mismatch: #{trunk.on_cli_mismatch_action}"
  puts "  External Reference ID: #{trunk.external_reference_id}"
  puts "  Emergency Enable All: #{trunk.emergency_enable_all}"
  puts "  RTP Timeout: #{trunk.rtp_timeout}"
  puts ''
end

# Create a voice out trunk with credentials_and_ip authentication
puts "\n=== Creating Voice Out Trunk (credentials_and_ip) ==="
suffix = SecureRandom.hex(4)

voice_out_trunk = DIDWW::Client.voice_out_trunks.new(
  name: "Ruby Outbound Trunk #{suffix}",
  # NOTE: 203.0.113.0/24 is RFC 5737 TEST-NET-3 documentation space.
  # Replace with the real CIDR of your SIP infrastructure — do NOT use 0.0.0.0/0
  # in production, that would expose the trunk to the entire internet.
  authentication_method: DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp.new(
    allowed_sip_ips: ['203.0.113.0/24'],
    tech_prefix: ''
  ),
  default_dst_action: DIDWW::Resource::VoiceOutTrunk::DEFAULT_DST_ACTION_ALLOW_CALLS,
  on_cli_mismatch_action: DIDWW::Resource::VoiceOutTrunk::ON_CLI_MISMATCH_ACTION_REJECT_CALL,
  external_reference_id: "ruby-example-#{suffix}",
  rtp_timeout: 60
)

if voice_out_trunk.save
  puts "Created voice out trunk: #{voice_out_trunk.id}"
  puts "  Name: #{voice_out_trunk.name}"
  puts "  Auth type: #{voice_out_trunk.authentication_method.type}"
  puts "  Username: #{voice_out_trunk.authentication_method.username}"
  puts "  Status: #{voice_out_trunk.status}"
  puts "  External Reference: #{voice_out_trunk.external_reference_id}"

  # Update trunk - change name and tech_prefix
  puts "\n=== Updating Voice Out Trunk ==="
  voice_out_trunk.name = "Updated Outbound Trunk #{suffix}"
  voice_out_trunk.authentication_method = DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp.new(
    allowed_sip_ips: ['10.0.0.0/8'],
    tech_prefix: '9'
  )

  if voice_out_trunk.save
    puts "Updated name: #{voice_out_trunk.name}"
    puts "  New auth type: #{voice_out_trunk.authentication_method.type}"
    puts "  Username: #{voice_out_trunk.authentication_method.username}"

    # Delete trunk
    puts "\n=== Deleting Voice Out Trunk ==="
    if voice_out_trunk.destroy
      puts 'Voice out trunk deleted'
    else
      puts 'Error deleting voice out trunk'
    end
  else
    puts "Error updating voice out trunk: #{voice_out_trunk.errors.full_messages}"
  end
else
  puts "Error creating voice out trunk: #{voice_out_trunk.errors.full_messages}"
end
