# frozen_string_literal: true
# Looks up Voice IN, Voice OUT, SMS OUT and SMS IN prices for one number.
#
# Prices are served by separate hosts (api-vin, api-vout and api-sms); the SDK
# mints a token for each of them on first use. The account needs a price plan
# of the service, otherwise DIDWW::Prices::PricePlanNotAssigned is raised.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/prices_lookup.rb [number]

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
  client.scope    = :read # a read token is enough for prices
end

number = ARGV.first || '18005550123'

def show(title)
  puts "\n=== #{title} ==="
  result = yield
  puts "#{result.total_records} matching price(s)"
  result.each { |price| puts "  #{price.to_h.compact}" }
rescue DIDWW::Prices::PricePlanNotAssigned, DIDWW::Prices::PriceNotFound => e
  puts "  #{e.class.name.split('::').last}: #{e.message}"
end

show('Voice IN') { DIDWW::Client.voice_in_prices.lookup(number: number) }
show('Voice IN, calls from the US') { DIDWW::Client.voice_in_prices.lookup(number: number, src_country_iso: 'US') }
show('Voice OUT') { DIDWW::Client.voice_out_prices.lookup(number: number) }
show('SMS OUT A2P') { DIDWW::Client.sms_out_a2p_prices.lookup(dst_number: number) }
show('SMS OUT P2P, whole country') { DIDWW::Client.sms_out_p2p_prices.lookup(dst_country_iso: 'US') }
show('SMS OUT OTP') { DIDWW::Client.sms_out_otp_prices.lookup(dst_number: number, dst_country_iso: 'US') }
show('SMS IN') { DIDWW::Client.sms_in_prices.lookup(dst_number: number) }

# Filters are checked before any request is sent:
begin
  DIDWW::Client.voice_out_prices.lookup(number: number, src_country_iso: 'US')
rescue ArgumentError => e
  puts "\nRejected locally: #{e.message}"
end
