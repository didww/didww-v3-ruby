# frozen_string_literal: true
# Runs the code snippets of the gem's README.md against the sandbox, one check
# per snippet (a snippet of independent statements is split along its comments),
# and deletes what the checks create, also when a check fails; exports cannot be
# deleted and an order is canceled while it is pending. Snippets that need
# production, a Rails app, a proxy or DIDWW staff are reported as skipped with
# the reason. Prints "Results: N passed, M failed" and exits 1 when a check fails.
#
# Placeholders of the snippets ('YOUR_API_KEY', 'uuid', 'sms-trunk-uuid', ...)
# are replaced with DIDWW_API_KEY, with resources of the sandbox account or
# with resources the check creates; changed DIDs and verifications are restored.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/test_readme.rb

require 'bundler/setup'
require 'didww'
require 'didww/callback/request_validator' # the Webhook Signature Validation snippet's require
require 'active_support/cache'
require 'fileutils'
require 'logger'
require 'open3'
require 'openssl'
require 'rbconfig'
require 'securerandom'
require 'tmpdir'

API_KEY = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
SUFFIX = SecureRandom.hex(4)
SMS_CONFIGURATIONS = DIDWW::ComplexObject::SmsTrunkConfiguration

# Stand-in for the README's MyCustomMiddleware: counts the JSON:API requests.
class MyCustomMiddleware < Faraday::Middleware
  @requests = 0

  class << self
    attr_accessor :requests
  end

  def call(env)
    self.class.requests += 1
    @app.call(env)
  end
end

# The JSON:API connection is built by the first configure of the process, so
# the README's customize_connection block (Connection Customization) is applied
# here, on the sandbox instead of production. The other configure calls below
# change the API key and the mode only.
DIDWW::Client.configure do |config|
  config.api_key  = API_KEY
  config.api_mode = :sandbox
  config.customize_connection do |conn|
    # conn is a JsonApiClient::Connection instance
    conn.use MyCustomMiddleware
    conn.faraday.options.timeout = 30
    conn.faraday.options.open_timeout = 10
  end
end

# ─── Helpers ───────────────────────────────────────────────

class Skip < StandardError; end

RESULTS = { passed: 0, failed: 0, skipped: 0 }
FAILURES = []

def section(title)
  puts "\n== #{title} =="
end

def check(name)
  yield
  RESULTS[:passed] += 1
  puts "  ✓ #{name}"
rescue Skip => e
  RESULTS[:skipped] += 1
  puts "  - #{name}: skipped, #{e.message}"
rescue StandardError => e
  RESULTS[:failed] += 1
  FAILURES << "#{name}: #{e.class}: #{e.message}"
  puts "  ✗ #{name}: #{e.class}: #{e.message}"
end

# A snippet that is not run at all
def skipped(name, reason)
  RESULTS[:skipped] += 1
  puts "  - #{name}: skipped, #{reason}"
end

def skip!(reason)
  raise Skip, reason
end

def verify(condition, expectation)
  raise "expected #{expectation}" unless condition
end

def saved!(resource)
  raise "#{resource.class.name.demodulize} not saved: #{resource.errors.full_messages.join('; ')}" unless resource.save

  resource
end

# Deletes what a check created; a failed delete is printed, not raised, so it
# does not hide the outcome of the check.
def destroy_all(*resources)
  resources.compact.select(&:persisted?).each do |resource|
    next if resource.destroy

    puts "    cleanup: #{resource.type} #{resource.id} not deleted: #{resource.errors.full_messages.join('; ')}"
  rescue StandardError => e
    puts "    cleanup: #{resource.type} #{resource.id} not deleted: #{e.message}"
  end
end

def first_did
  DIDWW::Client.dids.page(1).per(1).all.first || skip!('no DIDs on the account')
end

def first_sku
  group = DIDWW::Client.did_groups.includes(:stock_keeping_units).all.find { |g| g.stock_keeping_units&.any? }
  group&.stock_keeping_units&.first || skip!('no DID group with stock keeping units')
end

def create_http_in_trunk(name)
  saved!(DIDWW::Client.sms_trunks.new(
    name: "#{name} #{SUFFIX}",
    configuration: SMS_CONFIGURATIONS::HttpIn.new(
      url: 'https://example.com/sms',
      http_method: SMS_CONFIGURATIONS::HttpIn::HTTP_METHOD_GET
    )
  ))
end

# Signs a callback the way DIDWW does, see examples/webhook.rb
def sign_callback(secret, url, payload)
  uri = URI(url)
  normalized_url = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
  normalized_url += "?#{uri.query}" if uri.query
  OpenSSL::HMAC.hexdigest('SHA1', secret, normalized_url + payload.sort.flatten.join)
end

# ─── Installation ──────────────────────────────────────────

section 'Installation'

check("Installation: gem 'didww-v3'") do
  spec = Gem.loaded_specs['didww-v3']
  verify(spec, 'the didww-v3 gem in the bundle')
  puts "    didww-v3 #{spec.version}"
end

# ─── Quick Start ───────────────────────────────────────────

section 'Quick Start'

check('Quick Start') do
  DIDWW::Client.configure do |config|
    config.api_key  = API_KEY
    config.api_mode = :sandbox
  end

  # Check balance
  balance = DIDWW::Client.balance
  puts "    Balance: #{balance.total_balance}"

  # List DID groups with stock keeping units
  did_groups = DIDWW::Client.did_groups
               .includes(:stock_keeping_units)
               .where(area_name: 'Acapulco')
               .all

  puts "    DID groups: #{did_groups.count}"
end

# ─── Configuration ─────────────────────────────────────────

section 'Configuration'

check('Configuration: sandbox') do
  DIDWW::Client.configure do |config|
    config.api_key  = API_KEY
    config.api_mode = :sandbox
  end
  verify(DIDWW::Client.api_mode == :sandbox, 'the sandbox mode')
  puts "    API #{DIDWW::Client.api_base_url}, token service #{DIDWW::Client.auth_base_url}"
end

skipped('Configuration: production', 'this script runs on the sandbox only')
skipped('Connection Customization: proxy', 'needs a reachable proxy; the snippet uses proxy.example.com on production')

check('Connection Customization: custom middleware and timeouts') do
  # Applied by the configure at the top of this script
  before = MyCustomMiddleware.requests
  DIDWW::Client.balance
  options = DIDWW::Resource::Base.connection.faraday.options
  verify(MyCustomMiddleware.requests > before, 'MyCustomMiddleware to see the request')
  verify(options.timeout == 30 && options.open_timeout == 10, 'timeout 30 and open_timeout 10')
end

skipped('Connection Customization: customize_faraday proxy', 'needs a reachable proxy; the snippet uses proxy.example.com on production')

check('API Version: with_api_version') do
  countries = DIDWW::Client.with_api_version('2099-01-01') do
    verify(DIDWW::Client.api_version == '2099-01-01', 'the overridden version inside the block')
    DIDWW::Client.countries.all
  end
  puts "    #{countries.size} countries with API version 2099-01-01"
  verify(DIDWW::Client.api_version == DIDWW::Client::DEFAULT_API_VERSION, 'the default version after the block')

  # Not a YYYY-MM-DD date, and earlier than DEFAULT_API_VERSION
  rejected = ['2099-1-1', '2020-01-01'].all? do |version|
    DIDWW::Client.with_api_version(version) { nil }
    false
  rescue ArgumentError
    true
  end
  verify(rejected, 'ArgumentError for a malformed and for an earlier version')
rescue DIDWW::Auth::InvalidRequest => e
  skip!("the token service does not grant the snippet's version 2099-01-01 (#{e.message})")
end

# ─── Authentication ────────────────────────────────────────

section 'Authentication'

check('Scope') do
  DIDWW::Client.scope = :read # GET and HEAD only
  puts "    balance with a read token: #{DIDWW::Client.balance.total_balance}"
  DIDWW::Client.scope = :full
  DIDWW::Client.scope = nil # the default: scope is not sent, the token service grants full
ensure
  DIDWW::Client.scope = nil
end

check('Token cache: an ActiveSupport::Cache store') do
  original_store = DIDWW::Client.token_store
  DIDWW::Client.token_store = ActiveSupport::Cache::MemoryStore.new # Rails.cache in the README
  puts "    balance with the token in an ActiveSupport::Cache::MemoryStore: #{DIDWW::Client.balance.total_balance}"
ensure
  DIDWW::Client.token_store = original_store if original_store
end

check('Logging and instrumentation: mint_token.didww') do
  original_store = DIDWW::Client.token_store
  events = []
  logger = Logger.new($stdout) # Rails.logger in the README
  subscriber = ActiveSupport::Notifications.subscribe('mint_token.didww') do |event|
    aud = event.payload[:aud].join(', ')
    if event.payload[:exception]
      logger.warn("DIDWW token mint for #{aud} failed after #{event.duration.round} ms: #{event.payload[:exception].first}")
    else
      logger.info("DIDWW token minted for #{aud} in #{event.duration.round} ms")
    end
    events << event
  end
  DIDWW::Client.token_store = DIDWW::Auth::MemoryStore.new # empty, so the next call mints a token
  DIDWW::Client.balance
  verify(events.any? { |e| Array(e.payload[:aud]).include?(DIDWW::Client::API_AUDIENCE) }, 'a mint_token.didww event for api.didww.com')
ensure
  ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  DIDWW::Client.token_store = original_store if original_store
end

# ─── Read-Only Resources ───────────────────────────────────

section 'Read-Only Resources'

check('Read-Only Resources: countries') do
  countries = DIDWW::Client.countries.all
  country = DIDWW::Client.countries.find(countries.first.id)
  puts "    #{countries.size} countries, found #{country.first.name}"
end

check('Read-Only Resources: regions, cities, areas') do
  regions = DIDWW::Client.regions.all
  cities = DIDWW::Client.cities.all
  areas = DIDWW::Client.areas.all
  puts "    #{regions.size} regions, #{cities.size} cities, #{areas.size} areas"
end

check('Read-Only Resources: DID groups by number type') do
  did_groups = DIDWW::Client.did_groups
               .where(number_type: DIDWW::Resource::DidGroup::NUMBER_TYPE_TOLL_FREE)
               .includes(:stock_keeping_units)
               .all
  did_groups.first(3).each do |group|
    puts "    #{group.prefix} number_type=#{group.number_type} is_demo=#{group.is_demo} SKUs=#{group.stock_keeping_units&.size}"
  end
  verify(did_groups.all? { |g| g.number_type == DIDWW::Resource::DidGroup::NUMBER_TYPE_TOLL_FREE }, 'toll_free DID groups only')
end

check('Read-Only Resources: available DIDs') do
  available_dids = DIDWW::Client.available_dids
                   .includes('did_group.stock_keeping_units')
                   .all
  puts "    #{available_dids.size} available DIDs"
end

check('Read-Only Resources: public keys') do
  public_keys = DIDWW::Client.public_keys.all
  verify(public_keys.any?, 'public keys')
  puts "    #{public_keys.size} public keys"
end

check('Read-Only Resources: address requirements') do
  requirements = DIDWW::Client.address_requirements.all
  puts "    #{requirements.size} address requirements"
end

check('Read-Only Resources: balance') do
  balance = DIDWW::Client.balance
  verify(balance, 'the balance')
  puts "    total balance #{balance.total_balance}"
end

# ─── DIDs ──────────────────────────────────────────────────

section 'DIDs'

check('DIDs: list and update') do
  dids = DIDWW::Client.dids.all
  skip!('no DIDs on the account') if dids.empty?

  did = DIDWW::Client.dids.find(dids.first.id).first
  original_description = did.description
  original_capacity_limit = did.capacity_limit
  begin
    did.description = 'Updated'
    did.capacity_limit = 20
    saved!(did)
    puts "    #{did.number}: description=#{did.description} capacity_limit=#{did.capacity_limit}"
  ensure
    restore = DIDWW::Client.dids.find(did.id).first
    restore.description = original_description
    restore.capacity_limit = original_capacity_limit
    saved!(restore)
  end
end

check('DIDs: SMS routing') do
  did = DIDWW::Client.dids.includes(:did_group, :sms_trunk, :sms_trunk_group).all
                    .find { |d| Array(d.did_group&.features).include?(DIDWW::Resource::DidGroup::FEATURE_IN_SMS) }
  skip!('no DID with the sms_in feature') unless did

  original_trunk = did.sms_trunk
  original_group = did.sms_trunk_group
  trunk = nil
  group_member = nil
  group = nil
  routed = false
  begin
    trunk = create_http_in_trunk('README routing')
    group_member = create_http_in_trunk('README routing group member')
    # SMS trunks and SMS trunk groups share one name space
    group = DIDWW::Client.sms_trunk_groups.new(name: "README routing group #{SUFFIX}")
    group.relationships.sms_trunks = [group_member]
    saved!(group)

    did = DIDWW::Client.dids.find(did.id).first
    did.sms_trunk = DIDWW::Resource::SmsTrunk.load(id: trunk.id)
    routed = true
    saved!(did) # sends sms_trunk and sms_trunk_group: null

    did.sms_trunk_group = DIDWW::Resource::SmsTrunkGroup.load(id: group.id)
    saved!(did) # sends sms_trunk_group and sms_trunk: null

    routed_dids = DIDWW::Client.dids.where('sms_trunk.id': trunk.id).all
    current = DIDWW::Client.dids.includes(:sms_trunk, :sms_trunk_group).find(did.id).first
    verify(current.sms_trunk_group&.id == group.id && current.sms_trunk.nil?, 'the DID routed to the group only')
    puts "    #{did.number}: routed to the group, #{routed_dids.size} DID(s) left on the trunk"
  ensure
    begin
      if routed
        restore = DIDWW::Resource::Did.load(id: did.id)
        if original_trunk
          restore.sms_trunk = original_trunk
        elsif original_group
          restore.sms_trunk_group = original_group
        else
          restore.sms_trunk = nil
          restore.sms_trunk_group = nil
        end
        saved!(restore)
      end
    ensure
      # Deleting a group also deletes the trunks in it
      group&.persisted? ? destroy_all(group, trunk) : destroy_all(group_member, trunk)
    end
  end
end

# ─── Voice In Trunks ───────────────────────────────────────

section 'Voice In Trunks'

check('Voice In Trunks: create a SIP trunk') do
  trunk = DIDWW::Client.voice_in_trunks.new(
    name: "My SIP Trunk #{SUFFIX}",
    pop: DIDWW::Resource::VoiceInTrunk::POP_AMS,
    configuration: DIDWW::ComplexObject::SipConfiguration.new(
      username: '{DID}',
      host: 'sip.example.com',
      port: 5060,
      codecs: [
        DIDWW::ComplexObject::SipConfiguration::CODEC_PCMA,
        DIDWW::ComplexObject::SipConfiguration::CODEC_PCMU,
        DIDWW::ComplexObject::SipConfiguration::CODEC_TELEPHONE_EVENT
      ],
      ice_mode: DIDWW::ComplexObject::SipConfiguration::ICE_MODE_ACCEPT
    )
  )

  saved!(trunk)
  verify(trunk.pop == DIDWW::Resource::VoiceInTrunk::POP_AMS, 'pop ams')
  verify(trunk.configuration.codecs == %w[pcma pcmu telephone_event], 'the codecs in the given order')
  puts "    created SIP trunk #{trunk.id}"
ensure
  destroy_all(trunk)
end

check('Voice In Trunks: SIP registration') do
  trunk = DIDWW::Client.voice_in_trunks.new(
    name: "Office (registered) #{SUFFIX}",
    configuration: DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
      c.enabled_sip_registration = true
      c.use_did_in_ruri          = true
      c.cnam_lookup              = true
    end
  )
  saved!(trunk)
  verify(trunk.configuration.incoming_auth_username.present?, 'a server-generated incoming_auth_username')
  puts '    created with SIP registration, credentials generated'

  # Disable SIP registration by setting host
  trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
    c.host = 'sip.example.com'
  end
  saved!(trunk)
  fresh = DIDWW::Client.voice_in_trunks.find(trunk.id).first
  verify(fresh.configuration.enabled_sip_registration == false, 'SIP registration disabled')
  puts "    disabled by setting host: host=#{fresh.configuration.host}"
ensure
  destroy_all(trunk)
end

# ─── Voice Out Trunks ──────────────────────────────────────

section 'Voice Out Trunks'

check('Voice Out Trunks: create with credentials_and_ip') do
  trunk = DIDWW::Client.voice_out_trunks.new(
    name: "My Outbound Trunk #{SUFFIX}",
    on_cli_mismatch_action: 'reject_call',
    authentication_method: DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp.new(
      allowed_sip_ips: ['203.0.113.0/24']
    ),
    codecs: [
      DIDWW::Resource::VoiceOutTrunk::CODEC_OPUS,
      DIDWW::Resource::VoiceOutTrunk::CODEC_PCMA,
      DIDWW::Resource::VoiceOutTrunk::CODEC_TELEPHONE_EVENT
    ]
  )

  saved!(trunk)
  verify(trunk.authentication_method.username.present?, 'a server-generated username')
  verify(trunk.codecs == %w[opus pcma telephone_event], 'the codecs in the given order')
  puts "    created voice out trunk #{trunk.id}"
ensure
  destroy_all(trunk)
end

# ─── SMS Trunks ────────────────────────────────────────────

section 'SMS Trunks'

check('SMS Trunks: create, update and list') do
  configurations = DIDWW::ComplexObject::SmsTrunkConfiguration

  trunk = DIDWW::Client.sms_trunks.new(
    name: "Inbound webhook #{SUFFIX}",
    configuration: configurations::HttpIn.new(
      url: 'https://example.com/sms',
      http_method: configurations::HttpIn::HTTP_METHOD_POST,
      body_type: configurations::HttpIn::BODY_TYPE_JSON,
      body: '{"text":"{SMS_TEXT}","from":"{SMS_SRC_ADDR}","to":"{SMS_DST_ADDR}"}'
    )
  )
  saved!(trunk)

  # On update the configuration type must stay the same; attributes left out keep their values.
  trunk.configuration = configurations::HttpIn.new(url: 'https://example.com/sms/v2')
  saved!(trunk)
  verify(trunk.configuration.url == 'https://example.com/sms/v2', 'the updated url')

  # List by configuration type, with the group
  trunks = DIDWW::Client.sms_trunks.where('configuration.type': 'http_in,sms_to_email').includes(:sms_trunk_group).all
  verify(trunks.any? { |t| t.id == trunk.id }, 'the created trunk in the list')
  puts "    #{trunks.size} http_in / sms_to_email trunks"
ensure
  destroy_all(trunk)
end

check('SMS Trunks: regenerate credentials') do
  # An smpp_esme trunk, whose system_id and password DIDWW generates
  esme = saved!(DIDWW::Client.sms_trunks.new(
    name: "README ESME #{SUFFIX}",
    configuration: SMS_CONFIGURATIONS::SmppEsme.new(server_location: SMS_CONFIGURATIONS::SERVER_LOCATION_NYC)
  ))
  old_password = DIDWW::Client.sms_trunks.find(esme.id).first.configuration.password

  trunk = DIDWW::Client.sms_trunks.find(esme.id).first
  verify(trunk.regenerate_credentials, 'POST /sms_trunk_regenerate_credentials to succeed')
  trunk = DIDWW::Client.sms_trunks.find(trunk.id).first
  verify(trunk.configuration.password.present? && trunk.configuration.password != old_password, 'a new password')
  puts '    password regenerated'
ensure
  destroy_all(esme)
end

# ─── SMS Trunk Groups ──────────────────────────────────────

section 'SMS Trunk Groups'

check('SMS Trunk Groups: create with a trunk') do
  member = create_http_in_trunk('README group member')

  group = DIDWW::Client.sms_trunk_groups.new(name: "Inbound SMS #{SUFFIX}")
  group.relationships.sms_trunks = [DIDWW::Resource::SmsTrunk.load(id: member.id)]
  saved!(group)
  verify(group.sms_trunks_count == 1, 'sms_trunks_count 1')
  puts "    created SMS trunk group #{group.id} with #{group.sms_trunks_count} trunk"
ensure
  # Deleting a group also deletes the trunks in it
  group&.persisted? ? destroy_all(group) : destroy_all(member)
end

# ─── Sender ID Verifications ───────────────────────────────

section 'Sender ID Verifications'

check('Sender ID Verifications: route through an SMS trunk and unassign it') do
  verifications = DIDWW::Client.sender_id_verifications
                               .where(status: DIDWW::Resource::SenderIdVerification::STATUS_ACTIVE)
                               .includes(:sms_trunk)
                               .all
  verification = verifications.first
  skip!('no active Sender ID verification; verifications are created outside the API') unless verification
  sending_trunk = DIDWW::Client.sms_trunks.all.find(&:allow_out)
  skip!('no http_out, smpp_esme or smpp_smsc trunk on the account') unless sending_trunk

  original_trunk = verification.sms_trunk
  begin
    verification.sms_trunk = DIDWW::Resource::SmsTrunk.load(id: sending_trunk.id)
    saved!(verification)

    verification.sms_trunk = nil # outbound messages stop until a trunk is assigned again
    saved!(verification)
    puts "    #{verification.reference}: routed through #{sending_trunk.name}, then unassigned"
  ensure
    restore = DIDWW::Resource::SenderIdVerification.load(id: verification.id)
    restore.sms_trunk = original_trunk
    saved!(restore)
  end
end

# ─── Exports ───────────────────────────────────────────────

section 'Exports'

check('Exports: create an SMS-Out export') do
  filters = {
    from: '2026-10-01 00:00:00', # inclusive
    to: '2026-10-02 00:00:00',   # exclusive
    service_type: DIDWW::ComplexObject::ExportFilters::SERVICE_TYPE_A2P
  }
  sending_trunk = DIDWW::Client.sms_trunks.all.find(&:allow_out)
  filters[:sms_trunk_id] = [sending_trunk.id] if sending_trunk # sent as "sms_trunk.id"

  export = DIDWW::Client.exports.new(
    export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_OUT,
    filters: DIDWW::ComplexObject::ExportFilters.new(filters)
  )
  saved!(export)
  puts "    created export #{export.id} (#{export.status})#{' without the sms_trunk_id filter: no sending trunk' unless sending_trunk}"
end

check('Exports: download a completed export') do
  export = DIDWW::Client.exports.where(status: DIDWW::Resource::Export::STATUS_COMPLETED).all.first
  skip!('no completed export on the account yet') unless export

  file = export.download # binary Tempfile with the gzipped CSV
  csv  = export.csv      # StringIO with the decompressed CSV
  begin
    verify(file.size.positive?, 'a downloaded file')
    puts "    #{export.export_type} export #{export.id}: #{file.size} bytes, columns: #{csv.gets&.strip}"
  ensure
    file.close!
  end
end

# ─── Orders ────────────────────────────────────────────────

section 'Orders'

check('Orders: order by SKU') do
  sku = first_sku
  order = DIDWW::Client.orders.new(
    items: [
      DIDWW::ComplexObject::DidOrderItem.new(sku_id: sku.id, qty: 2) # 'sku-uuid' in the README
    ]
  )

  # Checked before the order is sent: the item must keep its sku_id and qty
  item = order.as_json_api.dig('attributes', 'items', 0, 'attributes') || {}
  verify(item['sku_id'] == sku.id && item['qty'] == 2, "the Hash item to keep sku_id and qty, it is sent as #{item.to_h}")
  saved!(order)
  puts "    order #{order.id}: #{order.status}"
ensure
  begin
    # cancel it
    if order&.persisted? && order.pending? && !order.destroy
      puts "    cleanup: order #{order.id} not canceled: #{order.errors.full_messages.join('; ')}"
    end
  rescue StandardError => e
    puts "    cleanup: order #{order.id} not canceled: #{e.message}"
  end
end

# ─── Emergency Services ────────────────────────────────────

section 'Emergency Services'

check('Emergency Services: requirements') do
  # List emergency requirements with filters
  requirements = DIDWW::Client.emergency_requirements
                 .includes(:country)
                 .all
  country = requirements.first&.country
  skip!('no emergency requirements') unless country

  # Filter by country and number type
  requirements = DIDWW::Client.emergency_requirements
                 .where('country.id': country.id, number_type: 'local')
                 .all

  requirements.first(3).each do |req|
    puts "    #{req.identity_type} / #{req.address_area_level} / #{req.estimate_setup_time} / #{req.requirement_restriction_message}"
  end
end

skipped('Emergency Services: create an emergency verification',
        'needs an emergency calling service, an address and a DID set up for it, and submits them for review by DIDWW')

check('Emergency Services: emergency calling services') do
  services = DIDWW::Client.emergency_calling_services
             .includes(:country, :dids)
             .all

  services.first(3).each do |svc|
    puts "    #{svc.name} — #{svc.status} (#{svc.number_type})"
  end
  puts "    #{services.size} emergency calling services"
end

skipped('Emergency Services: cancel an emergency calling service', 'cancels a live emergency calling service')

# ─── DID History ───────────────────────────────────────────

section 'DID History'

check('DID History') do
  # List recent DID history events (retained for the last 90 days)
  events = DIDWW::Client.did_history.all

  events.first(3).each do |event|
    puts "    #{event.created_at.iso8601}  #{event.did_number}  #{event.action}  via #{event.method}"
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
  puts "    #{events.size} events, #{assigned.size} assigned, #{per_number.size} for 12125551234, #{recent.size} in 7 days"
end

# ─── Prices ────────────────────────────────────────────────

section 'Prices'

check('Prices: lookups') do
  lookups = {
    'Voice IN' => -> { DIDWW::Client.voice_in_prices.lookup(number: '18005550123', src_country_iso: 'US') },
    'Voice OUT' => -> { DIDWW::Client.voice_out_prices.lookup(number: '493012345678') },
    'SMS OUT A2P' => -> { DIDWW::Client.sms_out_a2p_prices.lookup(dst_number: '4915123456789') },
    'SMS IN' => -> { DIDWW::Client.sms_in_prices.lookup(dst_country_iso: 'US') }
  }
  answered = lookups.count do |name, lookup|
    result = lookup.call
    price = result.first
    detail = name == 'Voice OUT' ? "category #{price&.category}" : "#{result.total_records} price(s)"
    puts "    #{name}: #{detail}"
    true
  rescue DIDWW::Prices::PricePlanNotAssigned, DIDWW::Prices::PriceNotFound => e
    puts "    #{name}: #{e.class.name.demodulize} (#{e.message})"
    false
  end
  skip!('no price plan or price for any of the lookups') if answered.zero?
end

check('Prices: price files') do
  dir = Dir.mktmpdir('didww-readme')
  begin
    prices = DIDWW::Client.voice_out_prices
    path = File.join(dir, 'voice_out_prices.csv.gz')

    # Download unless the copy at the path is current
    file = prices.fetch(path)
    puts "    fetch: modified=#{file.modified?} last_modified=#{file.last_modified} #{file.bytes_written} bytes"

    # Read the rows
    rows = 0
    DIDWW::Prices.each_row(path) do |row|
      rows += 1
      puts "    #{row['Prefix']}: #{row['Rate']}" if rows <= 2
    end
    verify(rows.positive?, 'rows in the price file')

    # Lower-level calls
    status = prices.head(if_modified_since: file.last_modified)
    puts "    head: not_modified=#{status.not_modified?} content_length=#{status.content_length} filename=#{status.filename}"

    prices.download(to: File.join(dir, 'voice_out_prices_2.csv.gz'))
    File.open(File.join(dir, 'copy.csv.gz'), 'wb') { |io| prices.download(to: io) }
    verify(File.size(File.join(dir, 'copy.csv.gz')).positive?, 'a download into an IO')
  rescue DIDWW::Prices::PricePlanNotAssigned => e
    skip!("no Voice OUT price plan on the account (#{e.message})")
  rescue DIDWW::Prices::ServiceUnavailable => e
    skip!("the price file is not available yet, retry in #{e.retry_after.inspect} s")
  ensure
    FileUtils.remove_entry(dir)
  end
end

# ─── Error Handling ────────────────────────────────────────

section 'Error Handling'

check('Error Handling: validation errors') do
  # Validation errors (422 Unprocessable Entity)
  trunk = DIDWW::Client.voice_in_trunks.new(
    name: "README invalid #{SUFFIX}",
    ringing_timeout: 100, # more than the allowed 32 seconds
    configuration: DIDWW::ComplexObject::SipConfiguration.new(host: 'sip.example.com')
  )
  unless trunk.save
    trunk.errors.full_messages.each do |msg|
      puts "    Validation error: #{msg}"
    end
  end
  verify(!trunk.persisted? && trunk.errors.any?, 'the trunk to be refused with validation errors')
ensure
  destroy_all(trunk)
end

check('Error Handling: HTTP errors') do
  rescued = nil
  # HTTP errors
  begin
    DIDWW::Client.dids.find(SecureRandom.uuid) # 'nonexistent-uuid' in the README
  rescue JsonApiClient::Errors::NotFound => e
    puts "    Not found: #{e.message}"
    rescued = :not_found
  rescue JsonApiClient::Errors::NotAuthorized => e
    puts "    Token refused twice: #{e.message}"
  rescue JsonApiClient::Errors::AccessDenied => e
    puts "    Access denied (e.g. a write with a read token): #{e.message}"
  rescue JsonApiClient::Errors::TooManyRequests => e
    puts "    Rate limited, retry in #{e.retry_after.inspect} s: #{e.message}"
  rescue JsonApiClient::Errors::ServerError => e
    puts "    Server error: #{e.message}"
  rescue JsonApiClient::Errors::ConnectionError => e
    puts "    Connection error: #{e.message}"
  rescue DIDWW::Auth::Error => e
    puts "    No access token: #{e.message} (status #{e.status}, retry after #{e.retry_after.inspect})"
  end
  verify(rescued == :not_found, 'JsonApiClient::Errors::NotFound for an unknown DID')
end

# ─── Dirty Tracking ────────────────────────────────────────

section 'Dirty Tracking'

check('Dirty Tracking: PATCH sends only the changed attributes') do
  did = DIDWW::Client.dids.find(first_did.id).first
  original_description = did.description
  begin
    did.description = 'Updated'
    sent = did.as_json_api['attributes'].keys
    verify(sent == ['description'], "only description in the PATCH payload, got #{sent}")
    saved!(did)
  ensure
    restore = DIDWW::Client.dids.find(did.id).first
    restore.description = original_description
    saved!(restore)
  end
end

# ─── Date and Datetime Fields ──────────────────────────────

section 'Date and Datetime Fields'

check('Date and Datetime Fields') do
  did = DIDWW::Client.dids.find(first_did.id).first
  verify(did.created_at.is_a?(Time), 'Did#created_at as a Time')
  verify(did.expires_at.nil? || did.expires_at.is_a?(Time), 'Did#expires_at as nil or a Time')
  puts "    created_at=#{did.created_at} expires_at=#{did.expires_at.inspect}"

  identity = DIDWW::Client.identities.page(1).per(1).all.first
  if identity
    identity = DIDWW::Client.identities.find(identity.id).first
    verify(identity.birth_date.nil? || identity.birth_date.is_a?(String), 'Identity#birth_date as nil or a String')
    puts "    birth_date=#{identity.birth_date.inspect}"
  else
    puts '    no identity on the account, birth_date not checked'
  end
end

# ─── Webhook Signature Validation ──────────────────────────

section 'Webhook Signature Validation'

check('Webhook Signature Validation') do
  # require 'didww/callback/request_validator' is at the top of this file
  validator = DIDWW::Callback::RequestValidator.new('YOUR_CALLBACK_SECRET')

  request_url = 'https://example.com/webhooks/didww'
  payload_params = { 'id' => SecureRandom.uuid, 'type' => 'orders', 'status' => 'completed' }
  signature = sign_callback('YOUR_CALLBACK_SECRET', request_url, payload_params)

  # In your webhook handler:
  valid = validator.validate(
    request_url,    # full original URL
    payload_params, # Hash of payload key-value pairs
    signature       # value of X-DIDWW-Signature header
  )
  verify(valid == true, 'a valid signature to validate')
  verify(validator.validate(request_url, payload_params.merge('status' => 'canceled'), signature) == false,
         'a tampered payload to fail')
  verify(DIDWW::Callback::RequestValidator::HEADER == 'X-DIDWW-Signature', 'the X-DIDWW-Signature header name')
end

check('Webhook Signature Validation: the validator required on its own') do
  # The snippet's require, in a process that has not loaded the rest of the gem
  code = <<~RUBY
    require 'didww/callback/request_validator'
    validator = DIDWW::Callback::RequestValidator.new('YOUR_CALLBACK_SECRET')
    validator.validate('https://example.com/webhooks/didww', { 'id' => '1' }, 'signature')
  RUBY
  output, status = Open3.capture2e(RbConfig.ruby, '-rbundler/setup', '-e', code, chdir: File.expand_path('..', __dir__))
  error = output.lines.find { |line| line.include?('Error') } || output
  verify(status.success?, "the snippet to run with only that require, it failed with: #{error.strip}")
end

skipped('Webhook Signature Validation: Rails example', 'runs in a Rails controller')

# ─── Enums ─────────────────────────────────────────────────

section 'Enums'

check('Enums: the documented constants') do
  names = %w[
    DIDWW::Resource::NumberTypes::NUMBER_TYPES
    DIDWW::Resource::VoiceInTrunk::POPS
    DIDWW::ComplexObject::ExportFilters::TRUNK_TYPES
    DIDWW::ComplexObject::ExportFilters::SERVICE_TYPES
    DIDWW::ComplexObject::SmsTrunkConfiguration::HttpIn::HTTP_METHODS
    DIDWW::ComplexObject::SmsTrunkConfiguration::HttpIn::BODY_TYPES
    DIDWW::ComplexObject::SmsTrunkConfiguration::SERVER_LOCATIONS
    DIDWW::Prices::VoiceOutPrice::CATEGORIES
    DIDWW::Resource::SenderIdVerification::STATUSES
    DIDWW::Resource::SenderIdVerification::SENDER_TYPES
    DIDWW::ComplexObject::SipConfiguration::CODECS
    DIDWW::ComplexObject::SipConfiguration::ICE_MODES
    DIDWW::ComplexObject::SipConfiguration::RTCP_MUX_MODES
    DIDWW::ComplexObject::SipConfiguration::RTCP_FEEDBACK_MODES
    DIDWW::ComplexObject::SipConfiguration::CODEC_PCMA
    DIDWW::ComplexObject::SipConfiguration::ICE_MODE_ACCEPT
    DIDWW::Resource::VoiceOutTrunk::CODECS
    DIDWW::Resource::VoiceOutTrunk::ICE_MODES
    DIDWW::Resource::VoiceOutTrunk::RTCP_MUX_MODES
    DIDWW::Resource::VoiceOutTrunk::RTCP_FEEDBACK_MODES
  ]
  missing = names.reject do |name|
    Object.const_get(name)
    true
  rescue NameError
    false
  end
  verify(missing.empty?, "every constant to exist, missing: #{missing.join(', ')}")
end

# ─── Summary ───────────────────────────────────────────────

puts "\n#{'=' * 50}"
puts "Results: #{RESULTS[:passed]} passed, #{RESULTS[:failed]} failed"
puts "Skipped: #{RESULTS[:skipped]}" if RESULTS[:skipped].positive?
unless FAILURES.empty?
  puts "\nFailures:"
  FAILURES.each { |failure| puts "  - #{failure}" }
end
puts '=' * 50

exit(RESULTS[:failed].positive? ? 1 : 0)
