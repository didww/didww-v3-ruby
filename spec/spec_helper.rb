# frozen_string_literal: true
require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'webmock/rspec'

require 'didww'
require 'support/stub_request_helper'
require 'support/request_body_helper' # NOSONAR
require 'support/shared_examples/requirement_validation' # NOSONAR
require 'support/shared_examples/patch_external_reference_id' # NOSONAR

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

  config.before do
    DIDWW::Client.api_key = StubRequestHelper::TEST_API_KEY
    DIDWW::Client.token_store = DIDWW::Auth::MemoryStore.new
    DIDWW::Client.token_provider = DIDWW::Auth::TokenProvider.new(sleeper: ->(_seconds) {})
    stub_didww_token
  end

  config.after do
    DIDWW::Client.scope = nil
    DIDWW::Client.logger = Logger.new(nil)
  end
end

DIDWW::Client.configure do |client|
  client.api_key  = StubRequestHelper::TEST_API_KEY
  client.api_mode = :sandbox
  client.logger = Logger.new(nil)
end
