# frozen_string_literal: true
# Reserves a DID and then places an order from that reservation.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_reservation_dids.rb

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

# Reserve the selected DID
puts "\n=== Reserving DID ==="
reservation = DIDWW::Client.did_reservations.new
reservation.available_did = available_did

if reservation.save
  puts "✓ Reserved: #{available_did.number}"
  puts "  Reservation ID: #{reservation.id}"
  puts "  Expires: #{reservation.expire_at}"
else
  puts "✗ Error creating reservation: #{reservation.errors.full_messages}"
  exit 1
end

# Purchase reserved DID
# Use DidOrderItem with did_reservation_id + sku_id
puts "\n=== Creating Order from Reservation ==="
reservation_did_item = DIDWW::ComplexObject::DidOrderItem.new(
  did_reservation_id: reservation.id,
  sku_id: sku.id
)

order = DIDWW::Client.orders.new(items: [reservation_did_item])

if order.save
  puts "✓ Order #{order.id}"
  puts "  Status: #{order.status}"
  puts "  Amount: #{order.amount}"
  puts "  Items: #{order.items.size}"
  if order.items && !order.items.empty?
    item = order.items.first
    puts "  Item type: #{item.type}"
  end
else
  puts "✗ Error creating order: #{order.errors.full_messages}"
end
