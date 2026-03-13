# frozen_string_literal: true
# CRUD for voice out trunks (requires account config).
# Note: Voice Out Trunks require additional account configuration.
# Contact DIDWW support to enable.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/voice_out_trunks.rb

require 'bundler/setup'
require 'didww'

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
  puts "  Username: #{trunk.username}"
  puts "  Default DST Action: #{trunk.default_dst_action}"
  puts "  On CLI Mismatch: #{trunk.on_cli_mismatch_action}"
  puts ''
end

# Create a voice out trunk
puts "\n=== Creating Voice Out Trunk ==="
suffix = SecureRandom.random_bytes(4).unpack1('H*')[0..7]

voice_out_trunk = DIDWW::Client.voice_out_trunks.new(
  name: "Ruby Outbound Trunk #{suffix}",
  allowed_sip_ips: ['0.0.0.0/0'],
  default_dst_action: 'allow_all',
  on_cli_mismatch_action: 'reject_call'
)

if voice_out_trunk.save
  puts "Created voice out trunk: #{voice_out_trunk.id}"
  puts "  Name: #{voice_out_trunk.name}"
  puts "  Username: #{voice_out_trunk.username}"
  puts "  Password: #{voice_out_trunk.password}"
  puts "  Status: #{voice_out_trunk.status}"

  # Update trunk
  puts "\n=== Updating Voice Out Trunk ==="
  voice_out_trunk.name = "Updated Outbound Trunk #{suffix}"
  voice_out_trunk.allowed_sip_ips = ['10.0.0.0/8']

  if voice_out_trunk.save
    puts "Updated name: #{voice_out_trunk.name}"

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
