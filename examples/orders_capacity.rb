# frozen_string_literal: true
# Purchases capacity by creating a capacity order item.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_capacity.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get capacity pools
puts '=== Finding Capacity Pools ==='
capacity_pools = DIDWW::Client.capacity_pools.all

if capacity_pools.empty?
  puts 'No capacity pools found'
  exit 1
end

capacity_pool = capacity_pools.first
puts "Selected capacity pool: #{capacity_pool.name}"
puts "  Monthly price: #{capacity_pool.monthly_price}"
puts "  Metered rate: #{capacity_pool.metered_rate}"

# Purchase capacity
puts "\n=== Creating Capacity Order ==="
capacity_item = DIDWW::ComplexObject::CapacityOrderItem.new(
  capacity_pool_id: capacity_pool.id,
  qty: 1
)

order = DIDWW::Client.orders.new(items: [capacity_item])

if order.save
  puts "Order #{order.id}"
  puts "  Status: #{order.status}"
  puts "  Amount: #{order.amount}"
  puts "  Items: #{order.items.size}"
else
  puts "Error creating order: #{order.errors.full_messages}"
end
