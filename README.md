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

## API Version

This SDK targets DIDWW API version `2026-10-22` (`DIDWW::Client::DEFAULT_API_VERSION`). The version is not sent as a header: it is requested in the `api_version` of every access token the SDK mints (see [Authentication](#authentication)).

| Gem Version | Branch | DIDWW API Version |
|-------------|--------|-------------------|
| **7.x** | [`master`](https://github.com/didww/didww-v3-ruby) | [`2026-10-22`](https://doc.didww.com/api3/2026-10-22/index.html) |
| **6.x** | [`release-6`](https://github.com/didww/didww-v3-ruby/tree/release-6) | [`2026-04-16`](https://doc.didww.com/api3/2026-04-16/index.html) |
| **5.x** | [`2022-05-10`](https://github.com/didww/didww-v3-ruby/tree/2022-05-10) | [`2022-05-10`](https://doc.didww.com/api3/2022-05-10/index.html) |
| **3.x** | [`release-3`](https://github.com/didww/didww-v3-ruby/tree/release-3) | [`2021-12-15`](https://doc.didww.com/api3/2021-12-15/index.html) |
| **2.x** | [`release-2`](https://github.com/didww/didww-v3-ruby/tree/release-2) | [`2021-04-19`](https://doc.didww.com/api3/2021-04-19/index.html) |
| **1.x** | [`release-1`](https://github.com/didww/didww-v3-ruby/tree/release-1) | [`2017-09-18`](https://doc.didww.com/api3/2017-09-18/index.html) |

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

- Scripts for every resource: [`examples/`](examples/README.md)
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

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | — | Your DIDWW API key. It is sent only to the token service. |
| `api_mode` | `:sandbox` | `:sandbox` or `:production`. |
| `api_version` | `DIDWW::Client::DEFAULT_API_VERSION` | API version requested in every token. See [API Version](#api-version-1). |
| `scope` | `nil` | `nil`, `:read` or `:full`. `nil` leaves the scope to the token service, which grants `full`. See [Scope](#scope). |
| `token_store` | `DIDWW::Auth::MemoryStore.new` | Cache for access tokens. See [Token cache](#token-cache). |
| `logger` | `Logger.new($stderr, level: :warn)` | Receives the token warnings. Set it to `Rails.logger`, or to `nil` to silence them. |
| `customize_connection { \|conn\| }` | — | Customizes the JSON:API connection. |
| `customize_faraday { \|faraday\| }` | — | Customizes the other connections: token service, prices, export download and file upload. |

### Environments

| Environment | API | Token service | Voice IN prices | Voice OUT prices | SMS prices |
|-------------|-----|---------------|-----------------|------------------|------------|
| `:production` | `https://api.didww.com/v3/` | `https://auth.didww.com` | `https://api-vin.didww.com/v3/` | `https://api-vout.didww.com/v3/` | `https://api-sms.didww.com/v3/` |
| `:sandbox` | `https://sandbox-api.didww.com/v3/` | `https://auth-sandbox.didww.com` | `https://api-vin-sandbox.didww.com/v3/` | `https://api-vout-sandbox.didww.com/v3/` | `https://api-sms-sandbox.didww.com/v3/` |

Each base URL can be overridden with an environment variable, for example to send the traffic through a proxy. Tokens are still requested for the production audiences listed in [Authentication](#authentication).

| Variable | Overrides |
|----------|-----------|
| `DIDWW_API_URL` | API base URL. End it with `/`. |
| `DIDWW_AUTH_URL` | Token service base URL |
| `DIDWW_API_VIN_URL` | Voice IN prices base URL |
| `DIDWW_API_VOUT_URL` | Voice OUT prices base URL |
| `DIDWW_API_SMS_URL` | SMS prices base URL |

### Connection Customization

Use `customize_connection` to customize the underlying JSON:API connection, for example to configure a proxy or add custom middleware:

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

The token service, prices, export download and file upload use their own Faraday connections. `customize_faraday` is called with each of them after it is built, so a proxy has to be set in both blocks:

```ruby
DIDWW::Client.configure do |config|
  config.api_key  = 'YOUR_API_KEY'
  config.api_mode = :production
  config.customize_connection { |conn| conn.faraday.proxy = 'http://proxy.example.com:8080' }
  config.customize_faraday do |faraday|
    # faraday is a Faraday::Connection instance
    faraday.proxy = 'http://proxy.example.com:8080'
  end
end
```

These connections open with a 10 s timeout and read with 60 s, except the token service, which reads with 10 s. A timeout set in `customize_faraday` applies to all of them, the token service included.

### API Version

Every token is requested for `DIDWW::Client.api_version`, which defaults to `DIDWW::Client::DEFAULT_API_VERSION`. `with_api_version` overrides it for a block. The override applies only to the current thread, so concurrent requests on other threads keep their own version:

```ruby
DIDWW::Client.with_api_version('2099-01-01') do
  DIDWW::Client.countries.all
end
```

Both `api_version=` and `with_api_version` raise `ArgumentError` for a value that is not a `YYYY-MM-DD` date, and for a version earlier than `DIDWW::Client::DEFAULT_API_VERSION`. The resources of earlier API versions are not in this gem: use didww-v3 6.x from the [`release-6`](https://github.com/didww/didww-v3-ruby/tree/release-6) branch for API `2026-04-16`.

## Authentication

Every request carries `Authorization: Bearer <token>`. The SDK mints the token itself with `POST /token` on the token service, sending your `api_key` in the `Api-Key` header. The API key is sent nowhere else. No code change is needed: `api_key` and `api_mode` work as before.

- **Audience.** Each token names the one service it is used for, as the production hostname of that service, in the sandbox too:

  | Calls | Token audience |
  |-------|----------------|
  | JSON:API resources, export download, encrypted file upload | `api.didww.com` |
  | Voice IN prices | `api-vin.didww.com` |
  | Voice OUT prices | `api-vout.didww.com` |
  | SMS OUT (A2P, P2P, OTP) and SMS IN prices | `api-sms.didww.com` |

  A token is minted on the first call to a service and reused until it expires. `GET /public_keys` is sent without a token.
- **Expiry and 401.** A cached token expires with its `expires_in`; the SDK adds no local expiry margin. When a request is answered 401, the SDK drops that token, mints a new one and sends the request again, once. A second 401 is raised (see [Error Handling](#error-handling)). A 403 is never retried.
- **Token service errors.** A 429 raises `DIDWW::Auth::RateLimited` with `retry_after`; until that time has passed, every further mint in the process raises the same error without a request. A 5xx answer, a connection failure or a timeout is retried with exponential backoff and jitter (0.5 s base, 8 s cap, 4 attempts in all). A 400, a 401 or a TLS failure is raised at once. See [Error Handling](#error-handling) for the error classes.

### Scope

```ruby
DIDWW::Client.scope = :read  # GET and HEAD only
DIDWW::Client.scope = :full
DIDWW::Client.scope = nil    # the default: scope is not sent, the token service grants full
```

A `read` token is enough for the price lookups and price files. A write with a `read` token is answered 403: resources raise `JsonApiClient::Errors::AccessDenied`, and `EncryptedFile.upload` raises `DIDWW::Resource::EncryptedFile::UploadError`.

The SDK compares each token it receives with what it asked for:

- a different `scope` (for example `full` granted for a `read` request) or a different `api_version` is logged as a warning through `DIDWW::Client.logger`, and the token is used;
- a token whose `aud` does not include the requested audience raises `DIDWW::Auth::InvalidGrant`.

### Token cache

Tokens are cached in `DIDWW::Client.token_store`, keyed by environment, API key (as a SHA-256 hash), audience, API version and scope. Each entry expires with the token's `expires_in`.

The default `DIDWW::Auth::MemoryStore` lives in the Ruby process, so a Puma or Sidekiq worker reuses a token across requests. Threads of one process that need the same token wait for a single mint. To share tokens between processes, use any store that responds to `read(key)`, `write(key, value, expires_in:)` and `delete(key)`, such as an `ActiveSupport::Cache::Store`:

```ruby
DIDWW::Client.token_store = Rails.cache
```

A store that keeps nothing, such as Rails' `:null_store`, makes the SDK mint a token on every call. A shared store holds live bearer tokens, so protect it like a credential. Processes that share a store can each mint once when a token is missing.

### Logging and instrumentation

Token warnings go to `DIDWW::Client.logger`. Each mint is also published as the `ActiveSupport::Notifications` event `mint_token.didww`, with the payload keys `aud`, `scope_requested`, `scope_granted`, `api_version` and `expires_in`. A mint that fails publishes the event too, with ActiveSupport's `exception` and `exception_object` keys and only `aud` and `scope_requested` set. A token taken from the cache, a mint refused inside a `Retry-After` window and an error shared with threads that waited for the same mint publish nothing. Neither the logs nor the event include the token or the API key.

```ruby
ActiveSupport::Notifications.subscribe('mint_token.didww') do |event|
  aud = event.payload[:aud].join(', ')
  if event.payload[:exception]
    Rails.logger.warn("DIDWW token mint for #{aud} failed after #{event.duration.round} ms: #{event.payload[:exception].first}")
  else
    Rails.logger.info("DIDWW token minted for #{aud} in #{event.duration.round} ms")
  end
end
```

### SDK design decisions

- **Audience strategy.** One token per audience, minted on first use, rather than one token naming every service. An account that never calls the prices services never requests their audiences, so a refused audience cannot break DID management, and every token is valid for one service only.
- **Cache store.** In-process memory by default, because Ruby processes serve many requests in their lifetime. A shared store is opt-in through `token_store`. Lifetime is decided by the server through the 401 refresh, not by a local expiry margin.
- **Gzip handling.** Price files are streamed to disk exactly as served, still gzipped and in binary mode, without being held in memory. The SDK never decompresses them on its own: `DIDWW::Prices.each_row` reads a downloaded file when you want rows.
- **Streamed-upload retry limitation.** The 401 retry sends the request body a second time. `EncryptedFile.upload` rewinds its multipart body for that; when the file IO cannot be rewound (a pipe or a socket), the refused token is still discarded, but the 401 is not retried and the upload raises `DIDWW::Resource::EncryptedFile::UploadError`. Pass a `File`, `Tempfile` or `StringIO` to keep the retry.

## Resources

### Read-Only Resources

```ruby
# Countries
countries = DIDWW::Client.countries.all
country = DIDWW::Client.countries.find('uuid')

# Regions, Cities, Areas
regions = DIDWW::Client.regions.all
cities = DIDWW::Client.cities.all
areas = DIDWW::Client.areas.all

# DID Groups (with stock keeping units), filtered by number type
did_groups = DIDWW::Client.did_groups
             .where(number_type: DIDWW::Resource::DidGroup::NUMBER_TYPE_TOLL_FREE)
             .includes(:stock_keeping_units)
             .all

# Available DIDs (with DID group and stock keeping units)
available_dids = DIDWW::Client.available_dids.all(include: 'did_group.stock_keeping_units')

# Public Keys
public_keys = DIDWW::Client.public_keys.all

# Address requirements
requirements = DIDWW::Client.address_requirements.all

# Balance (singleton)
balance = DIDWW::Client.balance
```

`DidGroup`, `AddressRequirement`, `EmergencyRequirement` and `EmergencyCallingService` carry a `number_type`, one of `DIDWW::Resource::NumberTypes::NUMBER_TYPES` (`local`, `national`, `mobile`, `toll_free`, `shared_cost`, `global`). `DidGroup#is_demo` flags demo groups.

### DIDs

```ruby
# List DIDs
dids = DIDWW::Client.dids.all

# Update DID
did = DIDWW::Client.dids.find('uuid').first
did.description = 'Updated'
did.capacity_limit = 20
did.save
```

#### SMS routing

A DID's inbound messages go to an SMS trunk or to an SMS trunk group. The two are exclusive: assigning one clears the other in the same request, as `voice_in_trunk` and `voice_in_trunk_group` do.

```ruby
did = DIDWW::Client.dids.find('uuid').first
did.sms_trunk = DIDWW::Resource::SmsTrunk.load(id: 'sms-trunk-uuid')
did.save # sends sms_trunk and sms_trunk_group: null

did.sms_trunk_group = DIDWW::Resource::SmsTrunkGroup.load(id: 'sms-trunk-group-uuid')
did.save # sends sms_trunk_group and sms_trunk: null

DIDWW::Client.dids.where('sms_trunk.id': 'sms-trunk-uuid').all
```

### Voice In Trunks

```ruby
trunk = DIDWW::Client.voice_in_trunks.new(
  name: 'My SIP Trunk',
  pop: DIDWW::Resource::VoiceInTrunk::POP_AMS,
  configuration: {
    type: 'sip_configurations',
    username: '{DID}',
    host: 'sip.example.com',
    port: 5060
  }
)

trunk.save
```

`pop` is a plain attribute, one of `DIDWW::Resource::VoiceInTrunk::POPS`. Leave it `nil` to let DIDWW choose.

#### SIP Registration (2026-04-16)

A Voice In Trunk can also be configured to authenticate inbound calls
via SIP registration credentials generated by DIDWW. The SDK
auto-cascades the dependent fields the server requires:

* setting `enabled_sip_registration = true` clears any previously-set
  `host` / `port` (the server rejects them with 422 otherwise);
* setting `host` to a non-blank value flips `enabled_sip_registration`
  back to `false` and forces `use_did_in_ruri = false` so the server
  accepts the disable PATCH.

DIDWW generates `incoming_auth_username` and `incoming_auth_password`
and surfaces them in the response when SIP registration is enabled.

```ruby
trunk = DIDWW::Client.voice_in_trunks.new(
  name: 'Office (registered)',
  configuration: DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
    c.enabled_sip_registration = true
    c.use_did_in_ruri          = true
    c.cnam_lookup              = true
  end
)
trunk.save
# trunk.configuration.incoming_auth_username -- server-generated
# trunk.configuration.incoming_auth_password -- server-generated
```

To disable SIP registration on an existing trunk, just set `host` —
the cascade flips `enabled_sip_registration` to `false` and
`use_did_in_ruri` to `false` automatically:

```ruby
trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
  c.host = 'sip.example.com'
end
trunk.save
```

### Voice Out Trunks

Voice Out Trunks use a polymorphic `authentication_method` (2026-04-16). Three types are supported:

- **`credentials_and_ip`** -- default method; `username` and `password` are server-generated and returned in the response.
- **`twilio`** -- requires a `twilio_account_sid`.
- **`ip_only`** -- read-only; can only be configured by DIDWW staff upon request. Cannot be set via the API.

```ruby
# NOTE: 203.0.113.0/24 is RFC 5737 TEST-NET-3 documentation space.
# Replace with the real CIDR of your SIP infrastructure.
trunk = DIDWW::Client.voice_out_trunks.new(
  name: 'My Outbound Trunk',
  on_cli_mismatch_action: 'reject_call',
  authentication_method: DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp.new(
    allowed_sip_ips: ['203.0.113.0/24']
  )
)

trunk.save
# trunk.authentication_method.username -- server-generated
# trunk.authentication_method.password -- server-generated
```

### SMS Trunks

An SMS trunk delivers inbound messages, accepts outbound ones, or both. Its `configuration` is one of five types under `DIDWW::ComplexObject::SmsTrunkConfiguration`:

| Type | Class | Notes |
|------|-------|-------|
| `sms_to_email` | `SmsToEmail` | Inbound messages are forwarded as email. `send_to`, `subject` and `message` are required. |
| `http_in` | `HttpIn` | Inbound messages are sent as an HTTP request to your `url`. `http_method` is one of `HttpIn::HTTP_METHODS`; `post` and `put` also need `body_type` (one of `HttpIn::BODY_TYPES`) and `body`. |
| `http_out` | `HttpOut` | You submit outbound messages over HTTP. `auth_name` and `auth_password` are generated. The submit URL is `trunk.host`. |
| `smpp_esme` | `SmppEsme` | You bind to DIDWW as an SMPP ESME. `server_location` is required; `system_id` and `password` are generated. |
| `smpp_smsc` | `SmppSmsc` | DIDWW binds to your SMSC with your `host`, `system_id`, `password` and `server_location`. |

The read-only `allow_in` and `allow_out` tell which directions a trunk handles. `server_location` is one of `SmsTrunkConfiguration::SERVER_LOCATIONS`; the sandbox accepts `nyc` only. A configuration type this gem does not know is read as `SmsTrunkConfiguration::Generic` and sent back unchanged.

```ruby
configurations = DIDWW::ComplexObject::SmsTrunkConfiguration

trunk = DIDWW::Client.sms_trunks.new(
  name: 'Inbound webhook',
  configuration: configurations::HttpIn.new(
    url: 'https://example.com/sms',
    http_method: configurations::HttpIn::HTTP_METHOD_POST,
    body_type: configurations::HttpIn::BODY_TYPE_JSON,
    body: '{"text":"{SMS_TEXT}","from":"{SMS_SRC_ADDR}","to":"{SMS_DST_ADDR}"}'
  )
)
trunk.save

# On update the configuration type must stay the same; attributes left out keep their values.
trunk.configuration = configurations::HttpIn.new(url: 'https://example.com/sms/v2')
trunk.save

# List by configuration type, with the group
DIDWW::Client.sms_trunks.where('configuration.type': 'http_in,sms_to_email').includes(:sms_trunk_group).all
```

The generated credentials of `http_out` and `smpp_esme` trunks are read-only and are never sent back on update. They are redacted in `#inspect`. To rotate them:

```ruby
trunk = DIDWW::Client.sms_trunks.find('uuid').first
trunk.regenerate_credentials # POST /sms_trunk_regenerate_credentials
trunk = DIDWW::Client.sms_trunks.find(trunk.id).first
trunk.configuration.password # the new password
```

### SMS Trunk Groups

An SMS trunk group spreads a DID's inbound messages over its trunks by their `priority`. `http_out` trunks cannot join a group. Deleting a group also deletes the trunks in it.

```ruby
group = DIDWW::Client.sms_trunk_groups.new(name: 'Inbound SMS')
group.relationships.sms_trunks = [DIDWW::Resource::SmsTrunk.load(id: 'sms-trunk-uuid')]
group.save
group.sms_trunks_count # => 1
```

### Exports

```ruby
export = DIDWW::Client.exports.new(
  export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_OUT,
  filters: DIDWW::ComplexObject::ExportFilters.new(
    from: '2026-10-01 00:00:00', # inclusive
    to: '2026-10-02 00:00:00',   # exclusive
    service_type: 'a2p',
    sms_trunk_id: ['sms-trunk-uuid'] # sent as "sms_trunk.id"
  )
)
export.save

# Once export.completed?
file = export.download # binary Tempfile with the gzipped CSV
csv  = export.csv      # StringIO with the decompressed CSV
```

`from` and `to` are required for every export type. The other filter keys depend on `export_type` (`cdr_in`, `cdr_out`, `sms_in`, `sms_out`); see `DIDWW::ComplexObject::ExportFilters`. `sms_trunk_id`, `sender_id_verification_id` and `voice_out_trunk_id` are sent as the dotted keys `sms_trunk.id`, `sender_id_verification.id` and `voice_out_trunk.id`.

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

### Emergency Services

```ruby
# List emergency requirements with filters
requirements = DIDWW::Client.emergency_requirements
               .includes(:country)
               .all

# Filter by country and number type
requirements = DIDWW::Client.emergency_requirements
               .where('country.id': 'country-uuid', number_type: 'local')
               .all

requirements.each do |req|
  puts req.identity_type
  puts req.address_area_level
  puts req.estimate_setup_time        # e.g. "7-14 days"
  puts req.requirement_restriction_message
end

# Create an emergency verification
verification = DIDWW::Client.emergency_verifications.new(
  address: DIDWW::Resource::Address.load(id: 'address-uuid'),
  emergency_calling_service:
    DIDWW::Resource::EmergencyCallingService.load(id: 'ecs-uuid'),
  dids: [DIDWW::Resource::Did.load(id: 'did-uuid')],
  external_reference_id: 'my-ref-123'
)

if verification.save
  puts "Created: #{verification.id} (status: #{verification.status})"
else
  puts "Errors: #{verification.errors.full_messages}"
end

# List emergency calling services
services = DIDWW::Client.emergency_calling_services
           .includes(:country, :dids)
           .all

services.each do |svc|
  puts "#{svc.name} — #{svc.status} (#{svc.number_type})"
end

# Cancel (destroy) an emergency calling service
svc = DIDWW::Client.emergency_calling_services.find('uuid').first
svc.destroy
```

### DID History

```ruby
# List recent DID history events (retained for the last 90 days)
events = DIDWW::Client.did_history.all

events.each do |event|
  puts "#{event.created_at.iso8601}  #{event.did_number}  #{event.action}  via #{event.method}"
end

# Filter by action
assigned = DIDWW::Client.did_history
           .where(action: DIDWW::Resource::DidHistory::ACTION_ASSIGNED)
           .all

# Filter by DID number
per_number = DIDWW::Client.did_history
             .where(did_number: '12125551234')
             .all

# Filter by date range
seven_days_ago = (Time.now - 7 * 24 * 60 * 60).iso8601
recent = DIDWW::Client.did_history
         .where(created_at_gteq: seven_days_ago)
         .all
```

## Prices

Prices are served by three services outside the JSON:API (hosts in [Environments](#environments)). Each price list has a price file and a lookup:

| Accessor | Service | Price file | Lookup | Lookup rows |
|----------|---------|------------|--------|-------------|
| `DIDWW::Client.voice_in_prices` | Voice IN | `prices.csv.gz` | `lookup/prices` | `DIDWW::Prices::VoiceInPrice` |
| `DIDWW::Client.voice_out_prices` | Voice OUT | `prices.csv.gz` | `lookup/prices` | `DIDWW::Prices::VoiceOutPrice` |
| `DIDWW::Client.sms_out_a2p_prices` | SMS | `sms_out/a2p/prices.csv.gz` | `sms_out/a2p/lookup/prices` | `DIDWW::Prices::SmsOutPrice` |
| `DIDWW::Client.sms_out_p2p_prices` | SMS | `sms_out/p2p/prices.csv.gz` | `sms_out/p2p/lookup/prices` | `DIDWW::Prices::SmsOutPrice` |
| `DIDWW::Client.sms_out_otp_prices` | SMS | `sms_out/otp/prices.csv.gz` | `sms_out/otp/lookup/prices` | `DIDWW::Prices::SmsOutPrice` |
| `DIDWW::Client.sms_in_prices` | SMS | `sms_in/prices.csv.gz` | `sms_in/lookup/prices` | `DIDWW::Prices::SmsInPrice` |

Each accessor returns a `DIDWW::Prices::Service`. The account needs a price plan of that service: without one, every call raises `DIDWW::Prices::PricePlanNotAssigned`.

### Price lookups

```ruby
result = DIDWW::Client.voice_in_prices.lookup(number: '18005550123', src_country_iso: 'US')
result.total_records
result.each do |price|
  puts "#{price.destination} #{price.source_type}: #{price.rate&.to_s('F')} USD/min"
end

DIDWW::Client.voice_out_prices.lookup(number: '493012345678').first.category
DIDWW::Client.sms_out_a2p_prices.lookup(dst_number: '4915123456789')
DIDWW::Client.sms_in_prices.lookup(dst_country_iso: 'US')
```

| Service | Filters |
|---------|---------|
| Voice IN | `number` (required), `src_country_iso` |
| Voice OUT | `number` (required); no other filter |
| SMS OUT and SMS IN | `dst_number`, `dst_country_iso`; at least one |

A missing or unknown filter raises `ArgumentError` before any request; blank values are dropped. The server checks the value formats and answers a bad value with 400 (`DIDWW::Prices::BadRequest`).

`lookup` returns a `DIDWW::Prices::LookupResult`, an `Enumerable` of price objects with `total_records` and `size`. Prices and fees are `BigDecimal`, `VoiceOutPrice#effective_at` is a `Time`, and `#to_h` returns every attribute. `VoiceOutPrice#category` is one of `DIDWW::Prices::VoiceOutPrice::CATEGORIES`.

The `id` of an SMS OUT or SMS IN lookup row is derived from its content: it changes when the row or its price changes, so do not use it to track a destination over time. A Voice OUT `id` names the answer by the plan, the prefix and the routing conditions, and stays the same when a re-import changes only the price. A Voice IN `id` names the answering row of the plan.

### Price files

The files are gzipped CSV. The SDK writes them exactly as served and never decompresses them.

```ruby
prices = DIDWW::Client.voice_out_prices

# Download unless the copy at the path is current
file = prices.fetch('/var/data/voice_out_prices.csv.gz')
file.modified?      # true: downloaded; false: answered 304, the file was kept
file.last_modified  # Time
file.bytes_written

# Read the rows
DIDWW::Prices.each_row('/var/data/voice_out_prices.csv.gz') do |row|
  puts "#{row['Prefix']}: #{row['Rate']}"
end

# Lower-level calls
status = prices.head(if_modified_since: file.last_modified)
status.not_modified?
status.content_length
status.filename     # from Content-Disposition, e.g. "voice_out_prices.csv.gz"

prices.download(to: '/tmp/voice_out_prices.csv.gz')
File.open('/tmp/copy.csv.gz', 'wb') { |io| prices.download(to: io) }
```

- `fetch(path)` sends the modification time of the file at `path` as `If-Modified-Since`, when the file is there. A file written by `download(to: path)` or `fetch` gets the `Last-Modified` of the response as its modification time, so the date matches the copy on disk. `fetch` trusts the modification time of any file at `path`: a file copied or changed by other means can be answered 304 and kept, so replace such a file with `download(to: path)`.
- `download(to:)` streams the body into an IO, or into a temp file next to `path` that is unique to the call and replaces `path` only on a 200. A 304 or an error leaves an existing file untouched, and concurrent downloads to one path do not mix their bytes. An IO target receives the body as it arrives, so after an error it may hold part of it.
- `head` and `download` return a `DIDWW::Prices::PriceFile`: `status`, `last_modified`, `content_length`, `filename`, `bytes_written`, `modified?` and `not_modified?`.
- Only `Last-Modified` and `If-Modified-Since` are used. The service sends no `ETag`, and the SDK never sends `If-None-Match`, which would make the service ignore `If-Modified-Since`.
- A 503 on a price file is retried up to 2 times when its `Retry-After` is 60 seconds or less, after waiting that long. Otherwise it raises `DIDWW::Prices::ServiceUnavailable` with `retry_after`.
- Redirects are not followed. Any status the API does not document for the call, such as a 3xx or a 202, raises `DIDWW::Prices::UnexpectedStatus`. An error is never turned into an empty file or an empty result.

## Filter Reference

> See [`FILTERS.md`](FILTERS.md) for the list of `filter[KEY]` keys accepted by every list endpoint at API version `2026-10-22`.

## Error Handling

The SDK uses [json_api_client](https://github.com/JsonApiClient/json_api_client) which raises exceptions for HTTP-level errors. Validation errors from the API are returned on the resource's `errors` collection after a failed `save`.

```ruby
# Validation errors (422 Unprocessable Entity)
trunk = DIDWW::Client.voice_in_trunks.new(name: '')
unless trunk.save
  trunk.errors.full_messages.each do |msg|
    puts "Validation error: #{msg}"
  end
end

# HTTP errors
begin
  DIDWW::Client.dids.find('nonexistent-uuid')
rescue JsonApiClient::Errors::NotFound => e
  puts "Not found: #{e.message}"
rescue JsonApiClient::Errors::NotAuthorized => e
  puts "Token refused twice: #{e.message}"
rescue JsonApiClient::Errors::AccessDenied => e
  puts "Access denied (e.g. a write with a read token): #{e.message}"
rescue JsonApiClient::Errors::TooManyRequests => e
  puts "Rate limited: #{e.message}"
rescue JsonApiClient::Errors::ServerError => e
  puts "Server error: #{e.message}"
rescue JsonApiClient::Errors::ConnectionError => e
  puts "Connection error: #{e.message}"
rescue DIDWW::Auth::Error => e
  puts "No access token: #{e.message} (status #{e.status}, retry after #{e.retry_after.inspect})"
end
```

`Export#download` raises the same `JsonApiClient::Errors` classes. It does not follow redirects: any status other than 200, such as a 3xx or 204, raises `JsonApiClient::Errors::UnexpectedStatus`.

Errors raised by the SDK itself inherit from `DIDWW::Error`.

**Token service** (`DIDWW::Auth::Error`, with `status`, `error`, `error_description` and `retry_after`). They are raised from any call that needs a new token:

| Class | Raised when |
|-------|-------------|
| `DIDWW::Auth::InvalidClient` | 401: the API key is missing, unknown or disabled, or the caller's IP is not allowed. Not retried. |
| `DIDWW::Auth::InvalidRequest` | 400 `invalid_request` or `invalid_scope`. |
| `DIDWW::Auth::RateLimited` | 429. `retry_after` is the number of seconds to wait. |
| `DIDWW::Auth::ServerError` | 5xx on every attempt. |
| `DIDWW::Auth::ConnectionError` | Connection failure or timeout on every attempt, or a TLS failure. |
| `DIDWW::Auth::InvalidGrant` | The token does not cover the requested audience. |
| `DIDWW::Auth::Error` | Any other status. |

**Prices** (`DIDWW::Prices::Error`, with `status`, `code`, `errors` and `retry_after`):

| Class | Status |
|-------|--------|
| `DIDWW::Prices::BadRequest` | 400, e.g. a filter value of the wrong format |
| `DIDWW::Prices::NotAuthorized` | 401 after the token was replaced once |
| `DIDWW::Prices::AccessDenied` | 403 |
| `DIDWW::Prices::PricePlanNotAssigned` | 404 `price_plan_not_assigned`; also any 404 on `head`, which has no body |
| `DIDWW::Prices::PriceNotFound` | 404 `price_not_found`: no price matches the lookup |
| `DIDWW::Prices::NotAcceptable` | 406 |
| `DIDWW::Prices::TooManyRequests` | 429, with `retry_after`. Not retried. |
| `DIDWW::Prices::ServiceUnavailable` | 503, with `retry_after`. Retried on price files only, see [Price files](#price-files). |
| `DIDWW::Prices::UnexpectedStatus` | Any other status |
| `DIDWW::Prices::ConnectionError` | Connection failure, timeout or TLS failure. Not retried. An error writing the file or IO is raised as it is. |

## Dirty Tracking

The SDK (via `json_api_client`) tracks which attributes have been modified. When you call `save` on a fetched resource, the resulting PATCH request sends only the changed attributes, avoiding unintended overwrites of server-side values.

```ruby
did = DIDWW::Client.dids.find('uuid').first
did.description = 'Updated'
did.save
# PATCH payload includes only "description", not all attributes
```

## Date and Datetime Fields

The SDK distinguishes between date-only and datetime fields:

- **Datetime fields** — deserialized as `Time`:
  - `created_at` — present on most resources
  - `updated_at` — `SmsTrunk`, `SmsTrunkGroup`
  - `expires_at` — `Did`, `DidReservation`, `Proof`, `EncryptedFile` (nullable)
  - `activated_at` — `EmergencyCallingService` (nullable)
  - `canceled_at` — `EmergencyCallingService` (nullable)
  - `effective_at` — `DIDWW::Prices::VoiceOutPrice` (nullable)
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

Initialize the validator with the callback secret that is enabled in the DIDWW User Panel (**APIs → DIDWW API 3 → Callback Secrets**). DIDWW signs every callback with it and sends callbacks only while a callback secret is enabled.

```ruby
require 'didww/callback/request_validator'

validator = DIDWW::Callback::RequestValidator.new("YOUR_CALLBACK_SECRET")

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
    validator = DIDWW::Callback::RequestValidator.new("YOUR_CALLBACK_SECRET")
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
`ReroutingDisconnectCode`, `Feature`, `AreaLevel`, `AddressVerificationStatus`, `StirShakenMode`,
`NumberType`, `Pop`, `ExportSmsTrunkType`, `SmsHttpMethod`, `SmsBodyType`, `SmsServerLocation`,
`VoiceOutPriceCategory`

\* `REPLACE_CLI` and `RANDOMIZE_CLI` require additional account configuration. Contact DIDWW support to enable these values.

The constants for `NumberType`, `Pop`, `ExportSmsTrunkType`, `SmsHttpMethod`, `SmsBodyType`, `SmsServerLocation` and `VoiceOutPriceCategory` are `DIDWW::Resource::NumberTypes::NUMBER_TYPES`, `DIDWW::Resource::VoiceInTrunk::POPS`, `DIDWW::ComplexObject::ExportFilters::TRUNK_TYPES`, `DIDWW::ComplexObject::SmsTrunkConfiguration::HttpIn::HTTP_METHODS` and `BODY_TYPES`, `DIDWW::ComplexObject::SmsTrunkConfiguration::SERVER_LOCATIONS` and `DIDWW::Prices::VoiceOutPrice::CATEGORIES`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/didww/didww-v3-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
