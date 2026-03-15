# frozen_string_literal: true
# Orders an available DID using included DID group SKU.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_available_dids.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get available DIDs with included DID group and SKUs
puts '=== Finding Available DIDs ==='
available_dids = DIDWW::Client.available_dids
                  .includes('did_group.stock_keeping_units')
                  .all

if available_dids.empty?
  puts 'No available DIDs found'
  exit 1
end

available_did = available_dids.first
puts "Selected available DID: #{available_did.number}"

# Get SKU from the included DID group
if available_did.did_group.nil? || available_did.did_group.stock_keeping_units.nil? || available_did.did_group.stock_keeping_units.empty?
  puts 'No stock_keeping_units found in included did_group'
  exit 1
end

sku = available_did.did_group.stock_keeping_units.first
puts "Selected SKU: #{sku.id} (monthly: #{sku.monthly_price})"

# Create order with available DID
# Use DidOrderItem with available_did_id + sku_id
puts "\n=== Creating Order with Available DID ==="
available_did_item = DIDWW::ComplexObject::DidOrderItem.new(
  available_did_id: available_did.id,
  sku_id: sku.id
)

order = DIDWW::Client.orders.new(items: [available_did_item])

if order.save
  puts "✓ Order #{order.id}"
  puts "  Status: #{order.status}"
  puts "  Amount: #{order.amount}"
  puts "  Items: #{order.items.size}"
  if order.items && !order.items.empty?
    item = order.items.first
    puts "  Item type: #{item.type}"
  end

  # Fetch DIDs from this order
  dids = DIDWW::Client.dids.where('order.id': order.id).all
  puts "  DIDs ordered: #{dids.size}"
  dids.each { |did| puts "    - #{did.number}" }
else
  puts "✗ Error creating order: #{order.errors.full_messages}"
end
