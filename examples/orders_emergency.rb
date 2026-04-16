# frozen_string_literal: true
# Inspects Emergency orders (2026-04-16).
#
# Emergency orders are created server-side when an EmergencyCallingService
# is activated or renewed — customers cannot POST them directly. They
# appear in GET /orders alongside DID/capacity/NANPA orders.
#
# Each Emergency order carries items of type "emergency_order_items":
#   * qty, emergency_calling_service_id  (request)
#   * nrc, mrc, prorated_mrc, billed_from, billed_to  (response)
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/orders_emergency.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

puts '=== All Orders (last 20, filtering for Emergency) ==='
orders = DIDWW::Client.orders.all
emergency_orders = orders.select { |o| o.description == 'Emergency' }
puts "Found #{emergency_orders.size} emergency orders out of #{orders.size} total"

emergency_orders.first(5).each do |order|
  puts "\nOrder: #{order.id}"
  puts "  Reference: #{order.reference}"
  puts "  Status: #{order.status}"
  puts "  Amount: #{order.amount}"
  puts "  Created: #{order.created_at}"
  puts "  External Reference: #{order.external_reference_id}" if order.external_reference_id

  order.items.each_with_index do |item, i|
    if item.is_a?(DIDWW::ComplexObject::EmergencyOrderItem)
      puts "  Item ##{i + 1} (emergency_order_items):"
      puts "    Qty: #{item.qty}"
      puts "    Emergency Calling Service ID: #{item.emergency_calling_service_id}"
      puts "    NRC: #{item.nrc}"
      puts "    MRC: #{item.mrc}"
      puts "    Prorated MRC: #{item.prorated_mrc}"
      puts "    Billed From: #{item.billed_from}"
      puts "    Billed To:   #{item.billed_to}"
    end
  end
end

# Follow the link from an EmergencyCallingService to its order (if any)
puts "\n=== Emergency Calling Service -> Order ==="
svc = DIDWW::Client.emergency_calling_services.includes(:order).all.first
if svc
  puts "ECS #{svc.id} (#{svc.name})"
  if svc.order
    puts "  -> Order #{svc.order.id} — status: #{svc.order.status}, amount: #{svc.order.amount}"
  else
    puts "  -> No order linked yet"
  end
else
  puts "No emergency_calling_services on this account"
end
