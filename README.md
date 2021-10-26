Ruby client for DIDWW API v3.

![Tests](https://github.com/didww/didww-v3-ruby/workflows/Tests/badge.svg)

About DIDWW API v3
-----

The DIDWW API provides a simple yet powerful interface that allows you to fully integrate your own applications with DIDWW services. An extensive set of actions may be performed using this API, such as ordering and configuring phone numbers, setting capacity, creating SIP trunks and retrieving CDRs and other operational data.

The DIDWW API v3 is a fully compliant implementation of the [JSON API specification](http://jsonapi.org/format/).

Read more https://doc.didww.com/api

Gem Versions **2.X.X** are intended to use with DIDWW API 3 version [2021-04-19](https://doc.didww.com/api3/2021-04-19/index.html).

Gem Versions **1.X.X** are intended to use with DIDWW API 3 version [2017-09-18](https://doc.didww.com/api3/2017-09-18/index.html).

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/didww/didww-v3-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
