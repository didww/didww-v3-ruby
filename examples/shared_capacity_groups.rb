# frozen_string_literal: true
# Lists shared capacity groups in capacity pools.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/shared_capacity_groups.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List shared capacity groups
puts '=== Existing Shared Capacity Groups ==='
shared_groups = DIDWW::Client.shared_capacity_groups
                 .includes(:capacity_pool)
                 .all

puts "Found #{shared_groups.size} shared capacity groups"

shared_groups.first(10).each do |group|
  puts "\nGroup: #{group.name}"
  puts "  ID: #{group.id}"
  puts "  Shared channels: #{group.shared_channels_count}"
  puts "  Metered channels: #{group.metered_channels_count}"
  if group.capacity_pool
    puts "  Capacity pool: #{group.capacity_pool.name}"
  end
end

# Get a specific capacity pool and show its shared capacity groups
puts "\n=== Capacity Pool with Shared Groups ==="
capacity_pools = DIDWW::Client.capacity_pools
                  .includes(:shared_capacity_groups)
                  .all

if !capacity_pools.empty?
  pool = capacity_pools.first
  puts "Capacity Pool: #{pool.name}"
  if pool.shared_capacity_groups && !pool.shared_capacity_groups.empty?
    puts "  Total channels: #{pool.total_channels_count}"
    puts "  Assigned channels: #{pool.assigned_channels_count}"
    puts '  Shared Capacity Groups:'
    pool.shared_capacity_groups.each do |group|
      puts "    - #{group.name} (#{group.shared_channels_count} shared, #{group.metered_channels_count} metered)"
    end
  else
    puts '  No shared capacity groups'
  end
end
