# frozen_string_literal: true
# Lists capacity pools with included shared capacity groups and qty-based
# pricings, and finds one pool by ID.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/capacity_pools.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List capacity pools with included shared capacity groups and qty-based pricings
puts '=== Capacity Pools ==='
capacity_pools = DIDWW::Client.capacity_pools
                 .includes(:shared_capacity_groups, :qty_based_pricings)
                 .all

puts "Found #{capacity_pools.size} capacity pools"

capacity_pools.each do |pool|
  puts "\nCapacity Pool: #{pool.name}"
  puts "  Total channels: #{pool.total_channels_count}"
  puts "  Assigned channels: #{pool.assigned_channels_count}"
  puts "  Renew date: #{pool.renew_date}"
  puts "  Monthly price: #{pool.monthly_price&.to_s('F')}"
  puts "  Metered rate: #{pool.metered_rate&.to_s('F')}"

  groups = pool.shared_capacity_groups || []
  unless groups.empty?
    puts "  Shared Capacity Groups (#{groups.size}):"
    groups.each do |group|
      puts "    - #{group.name} shared=#{group.shared_channels_count} metered=#{group.metered_channels_count}"
    end
  end

  pricings = pool.qty_based_pricings || []
  unless pricings.empty?
    puts "  Qty-based pricings (#{pricings.size}):"
    pricings.each do |pricing|
      puts "    - qty=#{pricing.qty} setup=#{pricing.setup_price&.to_s('F')} monthly=#{pricing.monthly_price&.to_s('F')}"
    end
  end
end

# Find a specific capacity pool
unless capacity_pools.empty?
  puts "\n=== Specific Capacity Pool ==="
  pool = DIDWW::Client.capacity_pools.find(capacity_pools.first.id).first
  puts "Found: #{pool.name} (#{pool.id}), minimum qty per order: #{pool.minimum_qty_per_order}"
end
