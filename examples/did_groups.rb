# frozen_string_literal: true
# Fetches DID groups with included SKUs and shows group details.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/did_groups.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Fetch DID groups with included stock_keeping_units
puts '=== DID Groups with SKUs ==='
did_groups = DIDWW::Client.did_groups
              .includes(:stock_keeping_units)
              .all

puts "Found #{did_groups.size} DID groups"

did_groups.first(3).each do |did_group|
  puts "\nDID Group: #{did_group.id}"
  puts "  Area: #{did_group.area_name}"
  puts "  Prefix: #{did_group.prefix}"
  puts "  Metered: #{did_group.is_metered}"
  puts "  Features: #{did_group.features_human}"

  if did_group.stock_keeping_units && !did_group.stock_keeping_units.empty?
    puts '  SKUs:'
    did_group.stock_keeping_units.each do |sku|
      puts "    - #{sku.id} (monthly: #{sku.monthly_price})"
    end
  end
end

# Find a specific DID group
if !did_groups.empty?
  puts "\n=== Specific DID Group ==="
  did_group = DIDWW::Client.did_groups
               .includes(:stock_keeping_units)
               .find(did_groups.first.id)
               .first
  puts "Found: #{did_group.area_name} (prefix: #{did_group.prefix})"
end
