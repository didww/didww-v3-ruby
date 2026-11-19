# frozen_string_literal: true
# Creates ONE order with the three DID order item variants, then fetches the
# ordered DIDs:
#   1. by SKU and quantity        - DidOrderItem(sku_id, qty): DIDWW picks the number
#   2. a specific available DID   - DidOrderItem(available_did_id, sku_id)
#   3. a previously reserved DID  - DidOrderItem(did_reservation_id, sku_id)
#
# All three are did_order_items on the wire, so they fit one order. Capacity
# items (capacity_order_items) cannot share an order with DID items: the API
# answers "items - should have same type". Buy capacity in an order of its own
# (see orders_capacity.rb).
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_all_item_types.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# The first SKU of the available DID's included DID group
def sku_of(available_did)
  sku = available_did.did_group&.stock_keeping_units&.first
  abort "No stock_keeping_units for available DID #{available_did.id}" unless sku
  sku
end

# Find available DIDs with their DID group and SKUs
puts '=== Finding Available DIDs ==='
available_dids = DIDWW::Client.available_dids
                 .includes('did_group.stock_keeping_units')
                 .all
abort 'Need at least 2 available DIDs for this example' if available_dids.size < 2

available_did = available_dids[0]
reserved_did = available_dids[1]
# Resolved before the reservation, so a missing SKU leaves nothing reserved
available_sku = sku_of(available_did)
reserved_sku = sku_of(reserved_did)
puts "Available DID 1: #{available_did.number} (SKU #{available_sku.id}) - ordered directly"
puts "Available DID 2: #{reserved_did.number} (SKU #{reserved_sku.id}) - reserved first"

# A SKU for the item by quantity, from a DID group
puts "\n=== Finding SKU for quantity order ==="
group_with_skus = DIDWW::Client.did_groups
                  .where(is_available: true) # numbers in stock
                  .includes(:stock_keeping_units)
                  .all
                  .find { |did_group| did_group.stock_keeping_units&.any? }
abort 'No DID group with stock_keeping_units found' unless group_with_skus
sku_for_qty = group_with_skus.stock_keeping_units.first
puts "SKU for qty order: #{sku_for_qty.id}"

# Reserve the second available DID
puts "\n=== Reserving DID ==="
reservation = DIDWW::Client.did_reservations.new(description: 'Reserved for all-item-types example')
reservation.available_did = reserved_did
abort "Error creating reservation: #{reservation.errors.full_messages}" unless reservation.save
puts "Reservation: #{reservation.id}"

# One order, three items
puts "\n=== Creating Order with All Item Types ==="
order = DIDWW::Client.orders.new(
  items: [
    DIDWW::ComplexObject::DidOrderItem.new(sku_id: sku_for_qty.id, qty: 1),
    DIDWW::ComplexObject::DidOrderItem.new(available_did_id: available_did.id, sku_id: available_sku.id),
    DIDWW::ComplexObject::DidOrderItem.new(did_reservation_id: reservation.id, sku_id: reserved_sku.id)
  ]
)
unless order.save
  # The order did not take the reserved DID, so release it
  puts "Error deleting reservation #{reservation.id}: #{reservation.errors.full_messages}" unless reservation.destroy
  abort "Error creating order: #{order.errors.full_messages}"
end

puts "Order ID: #{order.id}"
puts "  Amount: #{order.amount&.to_s('F')}"
puts "  Status: #{order.status}"
puts "  Created at: #{order.created_at}"
puts "  Reference: #{order.reference}"
puts "  Items: #{order.items.size}"
order.items.each_with_index do |item, i|
  puts "    Item #{i + 1}: type=#{item.type} qty=#{item.qty} sku=#{item.sku_id}"
end

# Fetch the DIDs that belong to this order
dids = DIDWW::Client.dids.where('order.id': order.id).all
puts "\n=== DIDs in order (#{dids.size}) ==="
dids.each { |did| puts "  #{did.id} | #{did.number} | capacity_limit=#{did.capacity_limit}" }
