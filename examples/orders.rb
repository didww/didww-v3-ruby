# frozen_string_literal: true
# Lists orders and creates/cancels a DID order using live SKU lookup.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List orders
puts '=== Existing Orders ==='
orders = DIDWW::Client.orders.all
puts "Found #{orders.size} orders"

orders.first(3).each do |order|
  items_desc = order.items.map(&:type).join(', ') if order.items
  puts "Order #{order.id}: #{order.status} ($#{order.amount})"
  puts "  Items: #{items_desc}" if items_desc
end

# Create an order with DID order items
puts "\n=== Creating DID Order ==="
did_groups = DIDWW::Client.did_groups
              .includes(:stock_keeping_units)
              .all

if did_groups.empty? || did_groups.first.stock_keeping_units.nil? || did_groups.first.stock_keeping_units.empty?
  puts 'No DID group with stock_keeping_units found'
  exit 1
end

did_group = did_groups.first
sku = did_group.stock_keeping_units.first

did_item = DIDWW::ComplexObject::DidOrderItem.new(
  sku_id: sku.id,
  qty: 1
)

order = DIDWW::Client.orders.new(allow_back_ordering: false, items: [did_item])

if order.save
  puts "Created order: #{order.id} - #{order.status}"
  puts "  Amount: #{order.amount}"
  puts "  Reference: #{order.reference}"

  # Cancel order (delete it)
  puts "\n=== Cancelling Order ==="
  if order.destroy
    puts 'Order cancelled'
  else
    puts "Error cancelling order: #{order.errors.full_messages}"
  end
else
  puts "Error creating order: #{order.errors.full_messages}"
end
