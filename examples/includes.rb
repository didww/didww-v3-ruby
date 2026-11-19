# frozen_string_literal: true
# Reads resources with included relationships (JSON:API `include`):
# regions with their country, DID groups with their SKUs, available DIDs with
# a nested include, DIDs with their voice trunk. Then shows how the SDK exposes
# an included relationship and a not-included one.
#
#   * Included: the response carries `data` for the relationship and the record
#     in `included`; the reader returns that record without another request.
#     An empty to-one relationship reads as nil.
#   * Not included: the response carries only `links`; the reader GETs the
#     relationship's `related` link, one request per record. Include what you read.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/includes.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Regions with included country
puts '=== Regions with country ==='
regions = DIDWW::Client.regions.includes(:country).page(1).per(3).all
regions.each do |region|
  puts "  #{region.name} (#{region.iso}) - country: #{region.country&.name}"
end

# DID groups with included stock keeping units (to-many)
puts "\n=== DID groups with SKUs ==="
did_groups = DIDWW::Client.did_groups.includes(:stock_keeping_units).page(1).per(3).all
did_groups.each do |group|
  skus = group.stock_keeping_units || []
  puts "  #{group.prefix} #{group.area_name} - #{skus.size} SKU(s)"
  skus.each { |sku| puts "    $#{sku.monthly_price&.to_s('F')}/mo, #{sku.channels_included_count} channels" }
end

# Available DIDs with a nested include: did_group and the group's SKUs
puts "\n=== Available DIDs with did_group.stock_keeping_units ==="
available_dids = DIDWW::Client.available_dids.includes('did_group.stock_keeping_units').page(1).per(3).all
available_dids.each do |available_did|
  group = available_did.did_group
  skus = group&.stock_keeping_units || []
  puts "  #{available_did.number} - group: #{group&.prefix} #{group&.area_name}, #{skus.size} SKU(s)"
end

# DIDs with included voice trunk; a DID without one reads nil
puts "\n=== DIDs with voice_in_trunk ==="
dids = DIDWW::Client.dids.includes(:voice_in_trunk).page(1).per(3).all
dids.each do |did|
  puts "  #{did.number} - trunk: #{did.voice_in_trunk&.name || '(none)'}"
end

# Included vs not included
puts "\n=== Included vs not included ==="
included = DIDWW::Client.regions.includes(:country).page(1).per(1).all.first
plain = DIDWW::Client.regions.page(1).per(1).all.first
if included && plain
  # The raw relationship object of the response
  puts "  included:     relationships.country has #{included.relationships.country.keys.sort.join(', ')}"
  puts "  not included: relationships.country has #{plain.relationships.country.keys.sort.join(', ')}"
  puts "  included:     region.country = #{included.country&.name} (from the included data, no request)"
  puts "  not included: region.country = #{plain.country&.name} (GET #{plain.relationships.country.dig('links', 'related')})"
end
