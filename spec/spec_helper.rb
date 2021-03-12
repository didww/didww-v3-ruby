# frozen_string_literal: true
require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'webmock/rspec'
require 'smart_rspec'
require 'byebug'

require 'didww'
require 'support/stub_request_helper'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include StubRequestHelper
end

DIDWW::Client.configure do |client|
  client.api_key  = ENV['API_KEY']
  client.api_mode = :sandbox
end
