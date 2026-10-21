# frozen_string_literal: true
# Downloads the Voice IN price file, checks it again with If-Modified-Since,
# and reads a few rows.
#
# The file is written exactly as served, still gzipped, and dated with the
# response's Last-Modified. fetch(path) sends the modification time of the file
# at path as If-Modified-Since, so while the price file is unchanged the second
# call, and any later run against the same file, is answered 304 and keeps it.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/prices_download.rb [dir]

require 'bundler/setup'
require 'didww'
require 'tmpdir'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

prices = DIDWW::Client.voice_in_prices
path = File.join(ARGV.first || Dir.tmpdir, 'voice_in_prices.csv.gz')

begin
  puts '=== HEAD ==='
  status = prices.head
  puts "Last-Modified: #{status.last_modified}, #{status.content_length} bytes, #{status.filename}"

  puts "\n=== fetch #{path} ==="
  file = prices.fetch(path)
  puts file.modified? ? "Downloaded #{file.bytes_written} bytes" : 'Not modified, file kept'

  puts "\n=== fetch again ==="
  file = prices.fetch(path)
  puts file.modified? ? "Downloaded #{file.bytes_written} bytes" : 'Not modified, file kept'

  puts "\n=== First rows ==="
  DIDWW::Prices.each_row(path).first(5).each do |row|
    puts "  #{row['Country']} #{row['Destination']} #{row['Source type']}: #{row['Rate (USD, excl. VAT)']}"
  end
rescue DIDWW::Prices::PricePlanNotAssigned => e
  puts "No Voice IN price plan on this account: #{e.message}"
rescue DIDWW::Prices::ServiceUnavailable => e
  puts "The price file is not available yet, retry in #{e.retry_after.inspect} s: #{e.message}"
end
