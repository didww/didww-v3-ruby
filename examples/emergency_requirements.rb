# frozen_string_literal: true
# Lists emergency service requirements for a country/did_group_type (2026-04-16).
#
# Emergency requirements describe what address precision, identity type,
# and supporting fields an end-customer must provide to enable 911/112
# on a DID. Each record reports a price preview in `meta` when the
# customer has a matching emergency plan.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/emergency_requirements.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

puts '=== Emergency Requirements ==='
requirements = DIDWW::Client.emergency_requirements
               .includes(:country, :did_group_type)
               .all
puts "Found #{requirements.size} emergency requirements"

requirements.first(5).each do |req|
  puts "\nRequirement: #{req.id}"
  puts "  Country: #{req.country&.name}"
  puts "  DID Group Type: #{req.did_group_type&.name}"
  puts "  Identity type required: #{req.identity_type}"
  puts "  Address area level: #{req.address_area_level}"
  puts "  Address mandatory fields: #{req.address_mandatory_fields&.join(', ')}"
  puts "  Estimated setup time (days): #{req.estimate_setup_time}"
  puts "  Restriction: #{req.requirement_restriction_message}" if req.requirement_restriction_message
  if req.meta
    puts "  Setup price: #{req.meta[:setup_price]}" if req.meta[:setup_price]
    puts "  Monthly price: #{req.meta[:monthly_price]}" if req.meta[:monthly_price]
  end
end

# Filter by country
if (first_req = requirements.first) && first_req.country
  country_id = first_req.country.id
  puts "\n=== Requirements for country #{first_req.country.name} ==="
  per_country = DIDWW::Client.emergency_requirements
                .where('country.id': country_id)
                .all
  puts "Found #{per_country.size} requirements"
end
