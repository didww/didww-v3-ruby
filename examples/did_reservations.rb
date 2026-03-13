# frozen_string_literal: true
# Lists DID reservations and available DIDs.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_reservations.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List DID reservations
puts '=== Existing DID Reservations ==='
reservations = DIDWW::Client.did_reservations
                .includes(:available_did)
                .all

puts "Found #{reservations.size} DID reservations"
reservations.first(10).each do |reservation|
  did_number = reservation.available_did ? reservation.available_did.number : 'unknown'
  puts "#{reservation.id}"
  puts "  DID: #{did_number}"
  puts "  Expires: #{reservation.expire_at}"
  puts "  Created: #{reservation.created_at}"
  puts ''
end

# List available DIDs
puts "\n=== Available DIDs ==="
available_dids = DIDWW::Client.available_dids
                  .includes(:did_group)
                  .all

puts "Found #{available_dids.size} available DIDs"
available_dids.first(10).each do |available_did|
  puts "#{available_did.number}"
  if available_did.did_group
    puts "  Group: #{available_did.did_group.area_name}"
    puts "  Prefix: #{available_did.did_group.prefix}"
  end
  puts ''
end

# Find a specific reservation if available
if !reservations.empty?
  puts "\n=== Specific Reservation Details ==="
  specific_reservation = DIDWW::Client.did_reservations
                         .find(reservations.first.id)
                         .first
  puts "Reservation: #{specific_reservation.id}"
  puts "  Expires at: #{specific_reservation.expire_at}"
  puts "  Created at: #{specific_reservation.created_at}"
end
