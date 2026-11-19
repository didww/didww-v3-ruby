# frozen_string_literal: true
# DID reservations: reserves an available DID, lists and finds reservations,
# and deletes the reservation, also when a step fails.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_reservations.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get an available DID to reserve
puts '=== Finding Available DID ==='
available_did = DIDWW::Client.available_dids
                .includes('did_group.stock_keeping_units')
                .page(1).per(1)
                .all
                .first
abort 'No available DIDs found' unless available_did
puts "Reserving DID: #{available_did.number}"
puts "  Group: #{available_did.did_group.area_name} (prefix #{available_did.did_group.prefix})" if available_did.did_group

# Create a reservation
puts "\n=== Creating Reservation ==="
reservation = DIDWW::Client.did_reservations.new(description: 'Ruby SDK example reservation')
reservation.available_did = available_did
abort "Error creating reservation: #{reservation.errors.full_messages}" unless reservation.save
puts "Created reservation: #{reservation.id}"
puts "  Description: #{reservation.description}"
puts "  Expires at: #{reservation.expires_at}"

begin
  # List reservations with the included available DID
  puts "\n=== All Reservations ==="
  reservations = DIDWW::Client.did_reservations
                 .includes(:available_did)
                 .all
  puts "Found #{reservations.size} reservations"
  reservations.each do |r|
    puts "  #{r.id} - #{r.available_did&.number || 'unknown'} (expires #{r.expires_at})"
  end

  # Find by ID
  puts "\n=== Specific Reservation ==="
  found = DIDWW::Client.did_reservations.find(reservation.id).first
  puts "Found reservation: #{found.id}, created at #{found.created_at}"
ensure
  puts "\n=== Deleting Reservation ==="
  puts reservation.destroy ? 'Deleted reservation' : "Error deleting reservation: #{reservation.errors.full_messages}"
end
