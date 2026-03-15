# frozen_string_literal: true
# Creates a DID order by SKU resolved from DID groups.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_by_sku.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get DID group with SKUs
puts '=== Finding DID Group with SKUs ==='
did_groups = DIDWW::Client.did_groups
              .includes(:stock_keeping_units)
              .all

if did_groups.empty? || did_groups.first.stock_keeping_units.nil? || did_groups.first.stock_keeping_units.empty?
  puts 'No DID group with stock_keeping_units found'
  exit 1
end

did_group = did_groups.first
sku = did_group.stock_keeping_units.first

puts "Selected DID Group: #{did_group.id}"
puts "Selected SKU: #{sku.id}"
puts "  Monthly price: #{sku.monthly_price}"

# Create order with 2 DIDs from this SKU
puts "\n=== Creating Order by SKU ==="
did_item = DIDWW::ComplexObject::DidOrderItem.new(
  sku_id: sku.id,
  qty: 2
)

order = DIDWW::Client.orders.new(items: [did_item])

if order.save
  puts "Order #{order.id}"
  puts "  Amount: #{order.amount}"
  puts "  Status: #{order.status}"
  puts "  Reference: #{order.reference}"

  if order.items && !order.items.empty?
    item = order.items.first
    puts "  Item type: #{item.type}"
  end
else
  puts "Error creating order: #{order.errors.full_messages}"
end
