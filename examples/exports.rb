# frozen_string_literal: true
# Lists CDR exports and their details.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/exports.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# List exports
puts '=== Existing Exports ==='
exports = DIDWW::Client.exports.all
puts "Found #{exports.size} exports"

exports.first(10).each do |export|
  puts "Export: #{export.id}"
  puts "  Type: #{export.export_type}"
  puts "  Status: #{export.status}"
  puts "  Created: #{export.created_at}"
  puts "  URL: #{export.url}" if export.url
  puts "  Callback URL: #{export.callback_url}" if export.callback_url
  puts ''
end

# Find a specific export if available
if !exports.empty?
  puts "\n=== Specific Export Details ==="
  specific_export = DIDWW::Client.exports
                    .find(exports.first.id)
                    .first
  puts "Export: #{specific_export.id}"
  puts "  Type: #{specific_export.export_type}"
  puts "  Status: #{specific_export.status}"
  puts "  Created: #{specific_export.created_at}"
  if specific_export.filters
    puts '  Filters:'
    puts "    Year: #{specific_export.filters.year}"
    puts "    Month: #{specific_export.filters.month}"
  end
end
