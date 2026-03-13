# frozen_string_literal: true
# Orders a DID number by NPA/NXX prefix.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_nanpa.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Step 1: find the NANPA prefix by NPA/NXX (e.g. 201-221)
nanpa_prefixes = DIDWW::Client.nanpa_prefixes.where(npanxx: '201221').all
abort 'NANPA prefix 201-221 not found' if nanpa_prefixes.empty?

nanpa_prefix = nanpa_prefixes.first
puts "NANPA prefix: #{nanpa_prefix.id} NPA=#{nanpa_prefix.npa} NXX=#{nanpa_prefix.nxx}"

# Step 2: find a DID group for this prefix and load its SKUs
did_groups = DIDWW::Client.did_groups
               .where('nanpa_prefix.id': nanpa_prefix.id)
               .includes(:stock_keeping_units)
               .all
abort 'No DID group found for this NANPA prefix' if did_groups.empty?

did_group = did_groups.first
sku = did_group.stock_keeping_units.first
abort 'No SKUs found for this DID group' if sku.nil?

puts "DID group: #{did_group.id}  SKU: #{sku.id} (monthly=#{sku.monthly_price})"

# Step 3: create the order
item = DIDWW::ComplexObject::DidOrderItem.new(
  sku_id: sku.id,
  nanpa_prefix_id: nanpa_prefix.id,
  qty: 1
)

order = DIDWW::Client.orders.new(allow_back_ordering: true, items: [item])
order.save

puts "Order #{order.id} amount=#{order.amount} status=#{order.status} ref=#{order.reference}"
