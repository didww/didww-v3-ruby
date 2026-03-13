# frozen_string_literal: true
# Lists regions with filters/includes and fetches a specific region.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/regions.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Get a country to filter regions
puts '=== Finding country ==='
countries = DIDWW::Client.countries.where(iso: 'US').all
if countries.empty?
  puts 'Country not found'
  exit 1
end

country = countries.first
puts "Selected country: #{country.name}"

# Fetch regions filtered by country with included country relationship
puts "\n=== Regions for #{country.name} ==="
regions = DIDWW::Client.regions
           .where('country.id': country.id)
           .includes(:country)
           .all

puts "Found #{regions.size} regions"
regions.first(5).each do |region|
  puts "#{region.id} - #{region.name} (#{region.iso})"
end

# Fetch a specific region
if !regions.empty?
  puts "\n=== Specific Region ==="
  region = DIDWW::Client.regions
            .includes(:country)
            .find(regions.last.id)
            .first
  puts "Found: #{region.name} (#{region.iso})"
end
