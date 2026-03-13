# frozen_string_literal: true
# Creates a DID order with all three item types (using unified DidOrderItem):
# 1. DidOrderItem - order by SKU and quantity (random DID)
# 2. AvailableDidOrderItem - order a specific available DID (via DidOrderItem + available_did_id)
# 3. ReservationDidOrderItem - order a previously reserved DID (via DidOrderItem + did_reservation_id)
#
# Then fetches the ordered DIDs.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_all_item_types.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Find available DIDs with their DID group and SKUs
puts '=== Finding Available DIDs ==='
available_dids = DIDWW::Client.available_dids
                  .includes('did_group.stock_keeping_units')
                  .all

if available_dids.size < 2
  puts 'Need at least 2 available DIDs for this example'
  exit 1
end

available_did1 = available_dids[0]
available_did2 = available_dids[1]

puts "Available DID 1: #{available_did1.number}"
puts "Available DID 2: #{available_did2.number}"

# Helper to get SKU from available DID
def get_sku(available_did)
  if available_did.did_group.nil? || available_did.did_group.stock_keeping_units.nil? || available_did.did_group.stock_keeping_units.empty?
    raise "No stock_keeping_units for available DID #{available_did.id}"
  end
  available_did.did_group.stock_keeping_units.first
end

sku1 = get_sku(available_did1)
sku2 = get_sku(available_did2)

puts "SKU 1: #{sku1.id}"
puts "SKU 2: #{sku2.id}"

# Get a SKU for the DidOrderItem (by quantity) from a different DID group
puts "\n=== Finding SKU for quantity order ==="
did_groups = DIDWW::Client.did_groups
              .includes(:stock_keeping_units)
              .all

sku_for_qty = nil
did_groups.each do |dg|
  if !dg.stock_keeping_units.nil? && !dg.stock_keeping_units.empty?
    sku_for_qty = dg.stock_keeping_units.first
    puts "SKU for qty order: #{sku_for_qty.id}"
    break
  end
end

if sku_for_qty.nil?
  puts 'No DID group with stock_keeping_units found'
  exit 1
end

# Reserve the second available DID
puts "\n=== Reserving DID ==="
reservation = DIDWW::Client.did_reservations.new
reservation.available_did = available_did2

if !reservation.save
  puts "Error creating reservation: #{reservation.errors.full_messages}"
  exit 1
end

puts "Reservation: #{reservation.id}"

# Build order with all three item types
puts "\n=== Creating Order with All Item Types ==="

# 1. DidOrderItem - order by SKU and quantity (random DID)
item_by_sku = DIDWW::ComplexObject::DidOrderItem.new(
  sku_id: sku_for_qty.id,
  qty: 1
)

# 2. AvailableDidOrderItem - order a specific available DID (use DidOrderItem with available_did_id)
item_by_available = DIDWW::ComplexObject::DidOrderItem.new(
  available_did_id: available_did1.id,
  sku_id: sku1.id
)

# 3. ReservationDidOrderItem - order a previously reserved DID (use DidOrderItem with did_reservation_id)
item_by_reservation = DIDWW::ComplexObject::DidOrderItem.new(
  did_reservation_id: reservation.id,
  sku_id: sku2.id
)

# Note: Each order must contain items of the SAME type only
# So we create separate orders for each item type combination

orders_created = []

# Order 1: By SKU
order1 = DIDWW::Client.orders.new(items: [item_by_sku])
if order1.save
  puts "\n✓ Order by SKU: #{order1.id}"
  puts "  Amount: #{order1.amount}, Status: #{order1.status}"
  orders_created << order1
else
  puts "\n✗ Error: #{order1.errors.full_messages}"
end

# Order 2: By Available DID
order2 = DIDWW::Client.orders.new(items: [item_by_available])
if order2.save
  puts "✓ Order by Available DID: #{order2.id}"
  puts "  Amount: #{order2.amount}, Status: #{order2.status}"
  orders_created << order2
else
  puts "✗ Error: #{order2.errors.full_messages}"
end

# Order 3: By Reservation
order3 = DIDWW::Client.orders.new(items: [item_by_reservation])
if order3.save
  puts "✓ Order by Reservation: #{order3.id}"
  puts "  Amount: #{order3.amount}, Status: #{order3.status}"
  orders_created << order3
else
  puts "✗ Error: #{order3.errors.full_messages}"
end

# Fetch DIDs from all orders
puts "\n=== DIDs Ordered ==="
total_dids = 0
orders_created.each_with_index do |order, idx|
  dids = DIDWW::Client.dids.where('order.id': order.id).all
  puts "Order #{idx + 1} (#{order.id}): #{dids.size} DID(s)"
  dids.each { |did| puts "  - #{did.number}" }
  total_dids += dids.size
end

puts "\n=== Summary ==="
puts '✓ All three order item types demonstrated:'
puts '  1. DidOrderItem(sku_id, qty) - order by SKU'
puts '  2. DidOrderItem(available_did_id, sku_id) - order available DID'
puts '  3. DidOrderItem(did_reservation_id, sku_id) - order reserved DID'
puts "Total DIDs ordered: #{total_dids}"
