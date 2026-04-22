Ruby client for DIDWW API v3.

![Tests](https://github.com/didww/didww-v3-ruby/workflows/Tests/badge.svg)
![Coverage](https://img.shields.io/endpoint?url=https://didww.github.io/didww-v3-ruby/badge.json)
[![Gem Version](https://badge.fury.io/rb/didww-v3.svg)](https://badge.fury.io/rb/didww-v3)
![Ruby](https://img.shields.io/badge/ruby-3.3%2B-blue)

About DIDWW API v3
-----

The DIDWW API provides a simple yet powerful interface that allows you to fully integrate your own applications with DIDWW services. An extensive set of actions may be performed using this API, such as ordering and configuring phone numbers, setting capacity, creating SIP trunks and retrieving CDRs and other operational data.

The DIDWW API v3 is a fully compliant implementation of the [JSON API specification](http://jsonapi.org/format/).

This SDK uses [json_api_client](https://github.com/JsonApiClient/json_api_client) for JSON:API serialization and deserialization.

Read more https://doc.didww.com/api

This SDK sends the `X-DIDWW-API-Version: 2026-04-16` header with every request by default.

Gem Versions **6.X.X** and branch [master](https://github.com/didww/didww-v3-ruby) are intended to use with DIDWW API 3 version [2026-04-16](https://doc.didww.com/api3/2026-04-16/index.html).

Gem Versions **5.X.X** and branch [release-5](https://github.com/didww/didww-v3-ruby/tree/release-5) are intended to use with DIDWW API 3 version [2022-05-10](https://doc.didww.com/api3/2022-05-10/index.html).

Gem Versions **3.X.X** and branch [release-3](https://github.com/didww/didww-v3-ruby/tree/release-3) are intended to use with DIDWW API 3 version [2021-12-15](https://doc.didww.com/api3/2021-12-15/index.html).

Gem Versions **2.X.X** and branch [release-2](https://github.com/didww/didww-v3-ruby/tree/release-2) are intended to use with DIDWW API 3 version [2021-04-19](https://doc.didww.com/api3/2021-04-19/index.html).

Gem Versions **1.X.X** and branch [release-1](https://github.com/didww/didww-v3-ruby/tree/release-1) are intended to use with DIDWW API 3 version [2017-09-18](https://doc.didww.com/api3/2017-09-18/index.html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'didww-v3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install didww-v3

## Requirements

- Ruby 3.3+

## Quick Start

```ruby
require 'didww'

DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :sandbox
end

# Check balance
balance = DIDWW::Client.balance
puts "Balance: #{balance.total_balance}"

# List DID groups with stock keeping units
did_groups = DIDWW::Client.did_groups.all(
  include: 'stock_keeping_units',
  filter: { area_name: 'Acapulco' }
)

puts "DID groups: #{did_groups.count}"
```

For details on obtaining your API key please visit https://doc.didww.com/api3/configuration.html

## Examples

- Rails integration sample: https://github.com/didww/didww-v3-rails-sample

## Configuration

```ruby
require 'didww'

# Sandbox
DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :sandbox
end

# Production
DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :production
end
```

### Environments

| Environment | Base URL |
|-------------|----------|
| `:production` | `https://api.didww.com/v3/` |
| `:sandbox` | `https://sandbox-api.didww.com/v3/` |

### Connection Customization

Use `customize_connection` to customize the underlying Faraday connection, for example to configure a proxy or add custom middleware:

```ruby
# Using a proxy
DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :production
  config.customize_connection do |conn|
    # conn is a JsonApiClient::Connection instance
    conn.faraday.proxy = 'http://proxy.example.com:8080'
  end
end
```

```ruby
# Adding custom middleware and timeouts
DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :production
  config.customize_connection do |conn|
    # conn is a JsonApiClient::Connection instance
    conn.use MyCustomMiddleware
    conn.faraday.options.timeout = 30
    conn.faraday.options.open_timeout = 10
  end
end
```

### API Version

The SDK sends `X-DIDWW-API-Version: 2026-04-16` by default. You can override it per block (e.g., to pin to a previous API version during migration):

```ruby
DIDWW::Client.with_api_version('2022-05-10') do
  DIDWW::Client.countries.all
end
```

## Resources

### Read-Only Resources

```ruby
# Countries
countries = DIDWW::Client.countries.all
country = DIDWW::Client.countries.find('uuid')

# Regions, Cities, Areas, POPs
regions = DIDWW::Client.regions.all
cities = DIDWW::Client.cities.all
areas = DIDWW::Client.areas.all
pops = DIDWW::Client.pops.all

# DID Group Types
types = DIDWW::Client.did_group_types.all

# DID Groups (with stock keeping units)
did_groups = DIDWW::Client.did_groups.all(include: 'stock_keeping_units')

# Available DIDs (with DID group and stock keeping units)
available_dids = DIDWW::Client.available_dids.all(include: 'did_group.stock_keeping_units')

# Public Keys
public_keys = DIDWW::Client.public_keys.all

# Requirements
requirements = DIDWW::Client.requirements.all

# Balance (singleton)
balance = DIDWW::Client.balance
```

### DIDs

```ruby
# List DIDs
dids = DIDWW::Client.dids.all

# Update DID
did = DIDWW::Client.dids.find('uuid')
did.description = 'Updated'
did.capacity_limit = 20
did.save
```

### Voice In Trunks

```ruby
trunk = DIDWW::Client.voice_in_trunks.new(
  name: 'My SIP Trunk',
  configuration: {
    type: 'sip_configurations',
    username: '{DID}',
    host: 'sip.example.com',
    port: 5060
  }
)

trunk.save
```

### Orders

```ruby
order = DIDWW::Client.orders.new(
  items: [
    {
      type: 'did_order_items',
      sku_id: 'sku-uuid',
      qty: 2
    }
  ]
)

order.save
```

## Date and Datetime Fields

The SDK distinguishes between date-only and datetime fields:

- **Datetime fields** — deserialized as `Time`:
  - `created_at` — present on most resources
  - `expires_at` — `Did`, `DidReservation`, `Proof`, `EncryptedFile` (nullable)
  - `activated_at` — `EmergencyCallingService` (nullable)
  - `canceled_at` — `EmergencyCallingService` (nullable)
- **Date-only fields** — deserialized as `Date`:
  - `Identity#birth_date`
- **Date-only fields kept as strings** — remain as `String`:
  - `CapacityPool#renew_date`, `EmergencyCallingService#renew_date` — `"YYYY-MM-DD"` (nullable)
- **String fields** (not numeric):
  - `EmergencyRequirement#estimate_setup_time` — e.g. `"7-14 days"`, `"1"`
  - `EmergencyRequirement#requirement_restriction_message` — nullable

**Important changes from previous API versions:**
- `expire_at` renamed to `expires_at` on `DidReservation` and `EncryptedFile`
- `renew_date` is a date-only string, NOT a datetime
- `estimate_setup_time` is a string, NOT an integer

```ruby
did = DIDWW::Client.dids.find("uuid").first
puts did.created_at   # => 2024-01-15 10:00:00 UTC  (Time)
puts did.expires_at   # => nil or 2025-01-15 10:00:00 UTC  (Time)

identity = DIDWW::Client.identities.find("uuid").first
puts identity.birth_date  # => 1990-05-20  (Date)
```

## Resource Relationships

See [docs/resource_relationships.md](docs/resource_relationships.md) for a Mermaid ER diagram showing all `has_one`, `has_many`, and `belongs_to` relationships between resources.

## Webhook Signature Validation

Validate incoming webhook callbacks from DIDWW using HMAC-SHA1 signature verification.

```ruby
require 'didww/callback/request_validator'

validator = DIDWW::Callback::RequestValidator.new("YOUR_API_KEY")

# In your webhook handler:
valid = validator.validate(
  request_url,    # full original URL
  payload_params, # Hash of payload key-value pairs
  signature       # value of X-DIDWW-Signature header
)
```

The signature header name is available as the constant `DIDWW::Callback::RequestValidator::HEADER`.

### Rails Example

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    validator = DIDWW::Callback::RequestValidator.new("YOUR_API_KEY")
    signature = request.headers[DIDWW::Callback::RequestValidator::HEADER]
    params_hash = request.POST

    if validator.validate(request.original_url, params_hash, signature)
      # Process the webhook
      head :ok
    else
      head :forbidden
    end
  end
end
```

## Enums

The SDK provides constants for all API option fields. These are defined as constants on their respective modules/classes:

`CallbackMethod`, `IdentityType`, `OrderStatus`, `ExportType`, `ExportStatus`, `CliFormat`,
`OnCliMismatchAction`\*, `MediaEncryptionMode`, `DefaultDstAction`, `VoiceOutTrunkStatus`,
`EmergencyCallingServiceStatus`, `EmergencyVerificationStatus`, `DiversionRelayPolicy`,
`TransportProtocol`, `Codec`, `RxDtmfFormat`, `TxDtmfFormat`, `SstRefreshMethod`,
`ReroutingDisconnectCode`, `Feature`, `AreaLevel`, `AddressVerificationStatus`, `StirShakenMode`

\* `REPLACE_CLI` and `RANDOMIZE_CLI` require additional account configuration. Contact DIDWW support to enable these values.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/didww/didww-v3-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
