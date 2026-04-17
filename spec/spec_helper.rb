# frozen_string_literal: true
require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'webmock/rspec'
require 'debug'

require 'didww'
require 'support/stub_request_helper'
require 'support/request_body_helper'
require 'support/shared_examples/requirement_validation'
require 'support/shared_examples/patch_external_reference_id'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include StubRequestHelper
  config.include RequestBodyHelper
end

DIDWW::Client.configure do |client|
  client.api_key  = ENV['API_KEY']
  client.api_mode = :sandbox
end
