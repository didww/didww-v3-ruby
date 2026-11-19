# frozen_string_literal: true
# Validates the signature of a DIDWW callback with DIDWW::Callback::RequestValidator.
#
# DIDWW signs every callback with the callback secret enabled in the User Panel
# and sends the signature in the X-DIDWW-Signature header. The signature is the
# hex HMAC-SHA1, keyed with the secret, of:
#   * the callback URL, normalized to scheme://host:port/path?query - the port is
#     always written, also the default one (https://example.com:443/...)
#   * followed by the payload's keys and values, sorted by key and concatenated
#     (status=completed&id=42 contributes "id42statuscompleted")
#
# This example builds a sample callback, signs it that way, and validates it
# and a tampered copy. It runs offline: no API key and no request is needed.
#
# Usage: ruby examples/webhook.rb

require 'bundler/setup'
require 'didww'
require 'openssl'
require 'uri'

callback_secret = 'your-callback-secret'
callback_url = 'https://example.com/webhooks/didww?account=main'
payload = {
  'id' => '7ae7c48f-d48a-499f-9dc1-c9217014b457',
  'type' => 'orders',
  'status' => 'completed'
}

# Signs a callback the way DIDWW does
def sign_callback(secret, url, payload)
  uri = URI(url)
  normalized_url = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
  normalized_url += "?#{uri.query}" if uri.query
  data = normalized_url + payload.sort.flatten.join
  OpenSSL::HMAC.hexdigest('SHA1', secret, data)
end

signature = sign_callback(callback_secret, callback_url, payload)
puts '=== Callback ==='
puts "URL: #{callback_url}"
puts "Payload: #{payload}"
puts "#{DIDWW::Callback::RequestValidator::HEADER}: #{signature}"

validator = DIDWW::Callback::RequestValidator.new(callback_secret)

puts "\n=== Validation ==="
puts "Signed payload   -> valid: #{validator.validate(callback_url, payload, signature)}"

tampered = payload.merge('status' => 'canceled')
puts "Tampered payload -> valid: #{validator.validate(callback_url, tampered, signature)}"
