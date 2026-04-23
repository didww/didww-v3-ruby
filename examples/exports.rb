# frozen_string_literal: true
# Creates and lists CDR exports (cdr_in / cdr_out).
#
# 2026-04-16 additions:
#   * external_reference_id — customer-supplied reference (max 100 chars)
#
# Filter semantics on CDR exports:
#   * filters.from — lower bound, INCLUSIVE  (server: time_start >= from)
#   * filters.to   — upper bound, EXCLUSIVE  (server: time_start <  to)
# To cover a whole day, pass from: "2026-04-15 00:00:00", to: "2026-04-16 00:00:00".
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/exports.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List existing exports
puts '=== Existing Exports ==='
exports = DIDWW::Client.exports.all
puts "Found #{exports.size} exports"

exports.first(5).each do |export|
  puts "Export: #{export.id}"
  puts "  Type: #{export.export_type}"
  puts "  Status: #{export.status}"
  puts "  Created: #{export.created_at}"
  puts "  URL: #{export.url}" if export.url
  puts "  Callback URL: #{export.callback_url}" if export.callback_url
  puts "  External Reference: #{export.external_reference_id}" if export.external_reference_id
  puts ''
end

# Create a CDR-In export for yesterday (from is inclusive, to is exclusive)
puts "\n=== Creating CDR-In Export (yesterday, 2026-04-16 external_reference_id) ==="
today     = Date.today
yesterday = today - 1
suffix    = SecureRandom.hex(4)

cdr_in_export = DIDWW::Client.exports.new(
  export_type: DIDWW::Resource::Export::EXPORT_TYPE_CDR_IN,
  filters: DIDWW::ComplexObject::ExportFilters.new(
    from: "#{yesterday} 00:00:00", # inclusive  (time_start >= this)
    to:   "#{today} 00:00:00"      # exclusive  (time_start <  this)
  ),
  external_reference_id: "ruby-cdr-in-#{suffix}"
)

if cdr_in_export.save
  puts "Created CDR-In export: #{cdr_in_export.id}"
  puts "  External Reference: #{cdr_in_export.external_reference_id}"
  puts "  Status: #{cdr_in_export.status}"
else
  puts "Error creating CDR-In export: #{cdr_in_export.errors.full_messages}"
end

# Find and inspect a specific export
if !exports.empty?
  puts "\n=== Specific Export Details ==="
  specific_export = DIDWW::Client.exports
                    .find(exports.first.id)
                    .first
  puts "Export: #{specific_export.id}"
  puts "  Type: #{specific_export.export_type}"
  puts "  Status: #{specific_export.status}"
  puts "  Created: #{specific_export.created_at}"
  puts "  External Reference: #{specific_export.external_reference_id}" if specific_export.external_reference_id
  if specific_export.filters
    puts '  Filters:'
    puts "    From (inclusive): #{specific_export.filters.from}" if specific_export.filters.respond_to?(:from)
    puts "    To (exclusive):   #{specific_export.filters.to}"   if specific_export.filters.respond_to?(:to)
  end
end
