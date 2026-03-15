# frozen_string_literal: true
# Lists countries, demonstrates filtering, and fetches one country by ID.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/countries.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List all countries
puts '=== All Countries ==='
countries = DIDWW::Client.countries.all
countries.first(5).each do |country|
  puts "#{country.name} (+#{country.prefix}) [#{country.iso}]"
end

# Filter countries by name
puts "\n=== Filtered Countries (United States) ==="
filtered = DIDWW::Client.countries.where(name: 'United States').all
puts "Found: #{filtered.size} countries"
filtered.each do |country|
  puts "#{country.name} (+#{country.prefix})"
end

# Find a specific country
if !filtered.empty?
  puts "\n=== Specific Country ==="
  country = DIDWW::Client.countries.find(filtered.first.id).first
  puts "Found: #{country.name}"
end
