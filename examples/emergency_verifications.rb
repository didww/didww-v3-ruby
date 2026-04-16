# frozen_string_literal: true
# Creates and lists Emergency Verifications (2026-04-16).
#
# An EmergencyVerification submits an address and a list of DIDs against an
# EmergencyCallingService for compliance review. The server returns a status
# of "pending" and later moves to "approved" / "rejected".
#
# Supported operations: index, show, create.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/emergency_verifications.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List existing verifications
puts '=== Emergency Verifications ==='
verifications = DIDWW::Client.emergency_verifications
                .includes(:address, :emergency_calling_service, :dids)
                .all
puts "Found #{verifications.size} emergency verifications"

verifications.first(5).each do |ev|
  puts "\nVerification: #{ev.id}"
  puts "  Reference: #{ev.reference}"
  puts "  Status: #{ev.status}"
  puts "  External Reference: #{ev.external_reference_id}" if ev.external_reference_id
  puts "  Address: #{ev.address&.id}"
  puts "  Emergency Calling Service: #{ev.emergency_calling_service&.id}"
  puts "  DIDs: #{ev.dids.map(&:number).join(', ')}" if ev.dids&.any?
  if ev.rejected?
    puts "  Reject reasons: #{Array(ev.reject_reasons).join(', ')}"
    puts "  Reject comment: #{ev.reject_comment}" if ev.reject_comment
  end
end

# Filter by status
puts "\n=== Only approved verifications ==="
approved = DIDWW::Client.emergency_verifications
           .where(status: DIDWW::Resource::EmergencyVerification::STATUS_APPROVED)
           .all
puts "Found #{approved.size} approved verifications"

# Create a new verification — requires an existing EmergencyCallingService,
# Address, and Did. Uncomment and replace the IDs below to try:
#
# suffix = SecureRandom.hex(4)
# verification = DIDWW::Client.emergency_verifications.new(
#   address: DIDWW::Resource::Address.load(id: '<address-uuid>'),
#   emergency_calling_service:
#     DIDWW::Resource::EmergencyCallingService.load(id: '<ecs-uuid>'),
#   dids: [DIDWW::Resource::Did.load(id: '<did-uuid>')],
#   external_reference_id: "ruby-ev-#{suffix}"
# )
#
# if verification.save
#   puts "Created verification #{verification.id} (status: #{verification.status})"
# else
#   puts "Error: #{verification.errors.full_messages}"
# end

puts "\nAvailable statuses: #{DIDWW::Resource::EmergencyVerification::STATUSES.join(', ')}"
