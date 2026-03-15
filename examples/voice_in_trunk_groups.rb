# frozen_string_literal: true
# CRUD for trunk groups with trunk relationships.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/voice_in_trunk_groups.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List trunk groups
puts '=== Existing Trunk Groups ==='
trunk_groups = DIDWW::Client.voice_in_trunk_groups
                .includes(:voice_in_trunks)
                .all

puts "Found #{trunk_groups.size} trunk groups"
trunk_groups.first(3).each do |group|
  trunks_count = group.voice_in_trunks ? group.voice_in_trunks.size : 0
  puts "#{group.name} (#{trunks_count} trunks)"
end

# Create a new trunk group
puts "\n=== Creating Trunk Group ==="
suffix = SecureRandom.random_bytes(4).unpack1('H*')[0..7]
trunk_group = DIDWW::Client.voice_in_trunk_groups.new(
  name: "Ruby Trunk Group #{suffix}",
  capacity_limit: 20
)

if trunk_group.save
  puts "Created trunk group: #{trunk_group.id} - #{trunk_group.name}"

  # Update trunk group
  puts "\n=== Updating Trunk Group ==="
  trunk_group.capacity_limit = 30
  if trunk_group.save
    puts "Updated trunk group: #{trunk_group.name} (capacity_limit: #{trunk_group.capacity_limit})"

    # Delete trunk group
    puts "\n=== Deleting Trunk Group ==="
    if trunk_group.destroy
      puts 'Trunk group deleted'
    end
  end
else
  puts "Error creating trunk group: #{trunk_group.errors.full_messages}"
end
