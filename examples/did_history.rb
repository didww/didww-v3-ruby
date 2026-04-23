# frozen_string_literal: true
# Lists DID ownership history (2026-04-16).
# Records are retained for the last 90 days only.
#
# Server-side filters supported:
#   did_number (eq), action (eq), method (eq),
#   created_at_gteq, created_at_lteq
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_history.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List most recent DID history events (server sorts by created_at desc)
puts '=== Recent DID History ==='
events = DIDWW::Client.did_history.all
puts "Found #{events.size} events in the last 90 days"

events.first(10).each do |event|
  puts "#{event.created_at.iso8601}  #{event.did_number.ljust(16)}  #{event.action.ljust(28)}  via #{event.method}"
end

# Filter by action
puts "\n=== Only 'assigned' events ==="
assigned = DIDWW::Client.did_history
           .where(action: DIDWW::Resource::DidHistory::ACTION_ASSIGNED)
           .all
puts "Found #{assigned.size} assignments"

# Filter by a specific DID number
if (first_event = events.first)
  number = first_event.did_number
  puts "\n=== History for DID #{number} ==="
  per_number = DIDWW::Client.did_history
               .where(did_number: number)
               .all
  per_number.each do |event|
    puts "#{event.created_at.iso8601}  #{event.action}  via #{event.method}"
  end
end

# Filter by date range (last 7 days)
seven_days_ago = (Time.now - 7 * 24 * 60 * 60).iso8601
puts "\n=== History since #{seven_days_ago} ==="
recent = DIDWW::Client.did_history
         .where(created_at_gteq: seven_days_ago)
         .all
puts "Found #{recent.size} events in the last 7 days"

puts "\nAvailable actions: #{DIDWW::Resource::DidHistory::ACTIONS.join(', ')}"
puts "Available methods: #{DIDWW::Resource::DidHistory::METHODS.join(', ')}"
