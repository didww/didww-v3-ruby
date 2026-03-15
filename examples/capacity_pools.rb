# frozen_string_literal: true
# Lists capacity pools with included shared capacity groups.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/capacity_pools.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List capacity pools with included shared capacity groups
puts '=== Capacity Pools ==='
capacity_pools = DIDWW::Client.capacity_pools
                  .includes(:shared_capacity_groups)
                  .all

puts "Found #{capacity_pools.size} capacity pools"

capacity_pools.each do |pool|
  puts "\nCapacity Pool: #{pool.name}"
  puts "  Total channels: #{pool.total_channels_count}"
  puts "  Assigned channels: #{pool.assigned_channels_count}"
  puts "  Monthly price: #{pool.monthly_price}"
  puts "  Metered rate: #{pool.metered_rate}"

  if pool.shared_capacity_groups && !pool.shared_capacity_groups.empty?
    puts '  Shared Capacity Groups:'
    pool.shared_capacity_groups.each do |group|
      puts "    - #{group.name} (#{group.shared_channels_count} channels)"
    end
  end
end
