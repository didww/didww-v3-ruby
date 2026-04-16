# frozen_string_literal: true
# Lists Address Verifications (with 2026-04-16 reject_comment / external_reference_id).
#
# AddressVerification ties an address to one or more DIDs and a set of
# supporting documents so DIDWW compliance can approve or reject the
# declaration. 2026-04-16 adds:
#   * reject_comment        — free-form comment accompanying a rejection
#   * external_reference_id — customer-supplied reference (max 100 chars)
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/address_verifications.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

puts '=== Address Verifications ==='
verifications = DIDWW::Client.address_verifications
                .includes(:address, :dids)
                .all
puts "Found #{verifications.size} address verifications"

verifications.first(5).each do |av|
  puts "\nVerification: #{av.id}"
  puts "  Reference: #{av.reference}"
  puts "  Status: #{av.status}"
  puts "  External Reference: #{av.external_reference_id}" if av.external_reference_id
  puts "  Service description: #{av.service_description}"  if av.service_description
  puts "  Address: #{av.address&.id}"
  puts "  DIDs: #{av.dids.map(&:number).join(', ')}" if av.dids&.any?
  if av.rejected?
    puts "  Reject reasons: #{Array(av.reject_reasons).join(', ')}"
    puts "  Reject comment: #{av.reject_comment}" if av.reject_comment
  end
end

# Filter: only rejected verifications
puts "\n=== Rejected verifications ==="
rejected = DIDWW::Client.address_verifications
           .where(status: DIDWW::Resource::AddressVerification::STATUS_REJECTED)
           .all
puts "Found #{rejected.size} rejected verifications"
rejected.first(3).each do |av|
  puts "  #{av.reference}: #{av.reject_comment || Array(av.reject_reasons).join(', ')}"
end

puts "\nAvailable statuses: #{DIDWW::Resource::AddressVerification::STATUSES.join(', ')}"
