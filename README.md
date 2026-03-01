Ruby client for DIDWW API v3.

![Tests](https://github.com/didww/didww-v3-ruby/workflows/Tests/badge.svg)
[![Gem Version](https://badge.fury.io/rb/didww-v3.svg)](https://badge.fury.io/rb/didww-v3)

About DIDWW API v3
-----

The DIDWW API provides a simple yet powerful interface that allows you to fully integrate your own applications with DIDWW services. An extensive set of actions may be performed using this API, such as ordering and configuring phone numbers, setting capacity, creating SIP trunks and retrieving CDRs and other operational data.

The DIDWW API v3 is a fully compliant implementation of the [JSON API specification](http://jsonapi.org/format/).

Read more https://doc.didww.com/api

This SDK sends the `X-DIDWW-API-Version: 2022-05-10` header with every request by default.

Gem Versions **4.X.X** and branch [master](https://github.com/didww/didww-v3-ruby) are intended to use with DIDWW API 3 version [2022-05-10](https://doc.didww.com/api3/2022-05-10/index.html).

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

client = DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :sandbox
end

# Check balance
balance = client.balance
puts "Balance: #{balance.total_balance}"

# List DID groups with stock keeping units
did_groups = client.did_groups.all(
  include: 'stock_keeping_units',
  filter: { area_name: 'Acapulco' }
)

puts "DID groups: #{did_groups.count}"
```

For more examples visit [examples](examples/).

For details on obtaining your API key please visit https://doc.didww.com/api3/configuration.html

## Examples

- Source code: [examples/](examples/)
- How to run: [examples/README.md](examples/README.md)
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

### API Version

The SDK sends `X-DIDWW-API-Version: 2022-05-10` by default. You can override it per block:

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

## Resource Relationships

See [docs/resource_relationships.md](docs/resource_relationships.md) for a Mermaid ER diagram showing all `has_one`, `has_many`, and `belongs_to` relationships between resources.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/didww/didww-v3-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
