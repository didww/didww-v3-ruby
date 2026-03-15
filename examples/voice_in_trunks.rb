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
