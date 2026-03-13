# frozen_string_literal: true
# Fetches and prints current account balance and credit.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/balance.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

balance = DIDWW::Client.balance
puts "Total Balance: #{balance.total_balance}"
puts "Balance: #{balance.balance}"
puts "Credit: #{balance.credit}"
