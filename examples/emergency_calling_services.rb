# frozen_string_literal: true
# Lists and cancels customer Emergency Calling Services (2026-04-16).
#
# An EmergencyCallingService represents a customer's 911/112 subscription
# attached to one or more DIDs. It ties an address, identity, DID group type
# and country together with a pricing snapshot (meta.setup_price, meta.monthly_price).
#
# Supported operations: index, show, destroy (cancel).
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/emergency_calling_services.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

puts '=== Emergency Calling Services ==='
services = DIDWW::Client.emergency_calling_services
           .includes(:country, :did_group_type, :dids)
           .all
puts "Found #{services.size} emergency calling services"

services.first(5).each do |svc|
  puts "\nService: #{svc.id}"
  puts "  Name: #{svc.name}"
  puts "  Reference: #{svc.reference}"
  puts "  Status: #{svc.status}"
  puts "  Country: #{svc.country&.name}"
  puts "  DID Group Type: #{svc.did_group_type&.name}"
  puts "  Activated: #{svc.activated_at}"
  puts "  Canceled: #{svc.canceled_at}"  if svc.canceled_at
  puts "  Renews: #{svc.renew_date}"     if svc.renew_date
  puts "  Attached DIDs: #{svc.dids.map(&:number).join(', ')}" if svc.dids&.any?
  if svc.meta
    puts "  Setup price:   #{svc.meta[:setup_price]}"   if svc.meta[:setup_price]
    puts "  Monthly price: #{svc.meta[:monthly_price]}" if svc.meta[:monthly_price]
  end
end

# Filter by status
puts "\n=== Only active emergency calling services ==="
active = DIDWW::Client.emergency_calling_services
         .where(status: 'active')
         .all
puts "Found #{active.size} active services"

# Cancel a service (destroy) — uncomment to try:
#
# if (svc = services.find { |s| s.status == 'active' })
#   puts "\nCancelling service #{svc.id}..."
#   if svc.destroy
#     puts 'Service cancelled'
#   else
#     puts "Error: #{svc.errors.full_messages}"
#   end
# end

puts "\nAvailable statuses: #{DIDWW::Resource::EmergencyCallingService::STATUSES.join(', ')}"
