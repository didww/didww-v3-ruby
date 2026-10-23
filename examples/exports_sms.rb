# frozen_string_literal: true
# Creates SMS exports (sms_in / sms_out) for yesterday and downloads the
# first completed one.
#
# Filters on SMS exports:
#   * from, to (required) — "YYYY-MM-DD HH:MM:SS" UTC; from inclusive, to exclusive
#   * source_address_eq / _cont, destination_address_eq / _cont, status, sms_id
#   * sms_trunk_id — one id or an array, sent as sms_trunk.id
#   * sms_in only:  trunk_type, one or more of ExportFilters::TRUNK_TYPES
#   * sms_out only: service_type (a2p or p2p), sender_id_verification_id
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/exports_sms.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

today     = Date.today
yesterday = today - 1
suffix    = SecureRandom.hex(4)

puts '=== Creating SMS-Out Export (A2P, yesterday) ==='
sms_out_export = DIDWW::Client.exports.new(
  export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_OUT,
  filters: DIDWW::ComplexObject::ExportFilters.new(
    from: "#{yesterday} 00:00:00",
    to:   "#{today} 00:00:00",
    service_type: 'a2p'
  ),
  external_reference_id: "ruby-sms-out-#{suffix}"
)
if sms_out_export.save
  puts "Created SMS-Out export: #{sms_out_export.id} (status: #{sms_out_export.status})"
else
  puts "Error creating SMS-Out export: #{sms_out_export.errors.full_messages}"
end

puts "\n=== Creating SMS-In Export (HTTP IN and email trunks, yesterday) ==="
sms_in_export = DIDWW::Client.exports.new(
  export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_IN,
  filters: DIDWW::ComplexObject::ExportFilters.new(
    from: "#{yesterday} 00:00:00",
    to:   "#{today} 00:00:00",
    trunk_type: [
      DIDWW::ComplexObject::ExportFilters::TRUNK_TYPE_HTTP_IN,
      DIDWW::ComplexObject::ExportFilters::TRUNK_TYPE_EMAIL
    ]
  ),
  external_reference_id: "ruby-sms-in-#{suffix}"
)
if sms_in_export.save
  puts "Created SMS-In export: #{sms_in_export.id} (status: #{sms_in_export.status})"
else
  puts "Error creating SMS-In export: #{sms_in_export.errors.full_messages}"
end

puts "\n=== Completed SMS-Out exports ==="
completed = DIDWW::Client.exports
            .where(export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_OUT, status: DIDWW::Resource::Export::STATUS_COMPLETED)
            .all
puts "Found #{completed.size} completed SMS-Out exports"

if (export = completed.first)
  csv = export.csv
  header = csv.gets
  puts "Export #{export.id} (#{export.export_type}) columns: #{header}"
end
