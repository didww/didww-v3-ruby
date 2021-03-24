Ruby client for DIDWW API v3.

![Tests](https://github.com/didww/didww-v3-ruby/workflows/Tests/badge.svg)

About DIDWW API v3
-----

The DIDWW API provides a simple yet powerful interface that allows you to fully integrate your own applications with DIDWW services. An extensive set of actions may be performed using this API, such as ordering and configuring phone numbers, setting capacity, creating SIP trunks and retrieving CDRs and other operational data.

The DIDWW API v3 is a fully compliant implementation of the [JSON API specification](http://jsonapi.org/format/).

Read more https://doc.didww.com/api

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'didww-v3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install didww-v3

## Usage

```ruby
require 'didww'

client = DIDWW::Client.configure do |config|
  config.api_key  = '34ffe988432b980f4ba19432539b704f'
  config.api_mode = :sandbox
end

client.balance
```

For details on obtaining your API key please visit https://doc.didww.com/api#introduction-api-keys

See integration example at https://github.com/didww/didww-v3-rails-sample

## Encryption algorithm

Pseudocode

```
# parameter file - user provided file.
# returns binary content of a file as string.
function file_binary_content(file) { ... }

# parameter str - string.
# returns base64 encoded string.
base64_encode(str) { ... }

# parameter size - integer number of bytes.
# returns array of random bytes.
generate_random_bytes(size)

# parameter size - AES algorithm size (128, 256, 512, ...).
# parameter mode - AES algorighm mode (ECB, CBC, CFP, ...).
# parameter key - AES key of appropriate size (8 times smaller than size).
# parameter iv - AES iv of appropriate size (16 times smaller than size).
# parameter data - string that we want to encrypt.
# returns encrypted binary string.
# https://tools.ietf.org/html/rfc3602
encrypt_aes(size, mode, key, iv, data)

# parameter bytes - array of bytes.
# returns converted bytes array to hex string, each byte represents by 2 chars.
bytes_to_hex(bytes)

# parameter digest - digest mode used for OAEP padding (SHA128, SHA256, SHA512, ...).
# parameter label - label string used for OAEP padding.
# parameter data - string that we want to encrypt.
# returns encrypted binary string by RSA algorithm with OAEP padding.
# https://tools.ietf.org/html/rfc8017
encrypt_rsa_oeap(digest, label, public_key, data)

function encrypt (file) {
  binary = file_binary_content(file)
  binary_base64 = base64_encode(binary)
  aes_key = generate_random_bytes(32)
  aes_iv = generate_random_bytes(16)
  encrypted_aes = encrypt_aes(256, 'CBC', aes_key, aes_iv, binary_base64)
  aes_key_hex = bytes_to_hex(aes_key)
  aes_iv_hex = bytes_to_hex(aes_iv)
  aes_credentials = "#{aes_key_hex}:::#{aes_iv_hex}"
  encrypted_rsa_a = encrypt_rsa_oeap('SHA256', '', public_keys[0], aes_credentials)
  encrypted_rsa_b = encrypt_rsa_oeap('SHA256', '', public_keys[1], aes_credentials)
  encrypted_rsa_a_base64 = base64_encode(encrypted_rsa_a)
  encrypted_rsa_b_base64 = base64_encode(encrypted_rsa_b)
  return "#{encrypted_rsa_a_base64}:::#{encrypted_rsa_b_base64}:::#{encrypted_aes}"
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/didww/didww-v3-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
