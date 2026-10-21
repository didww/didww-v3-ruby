# frozen_string_literal: true
RSpec.describe DIDWW::Client do
  let(:api_key) { 'f02c46006f6fa4746cd019abffb0a949' }
  let(:sandbox_uri) { 'https://sandbox-api.didww.com/v3/' }
  let(:prod_uri) { 'https://api.didww.com/v3/' }

  after do
    # restore DIDWW client configuration
    DIDWW::Client._customize_conn_block = nil
    DIDWW::Client._customize_faraday_block = nil
    DIDWW::Client.api_version = DIDWW::Client::DEFAULT_API_VERSION
    DIDWW::Client.configure do |client|
      client.api_key  = StubRequestHelper::TEST_API_KEY
      client.api_mode = :sandbox
    end
  end

  it 'configures' do
    DIDWW::Client.configure do |client|
      client.api_key  = api_key
      client.api_mode = :production
    end

    expect(DIDWW::Client.api_key).to eq(api_key)
    expect(DIDWW::Client.api_mode).to eq(:production)
    expect(DIDWW::Client.api_base_url).to eq(prod_uri)
  end

  it 'defaults to sandbox mode' do
    DIDWW::Client.configure do |client|
      client.api_key = api_key
    end
    expect(DIDWW::Client.api_mode).to eq(:sandbox)
    expect(DIDWW::Client.api_base_url).to eq(sandbox_uri)
  end

  it 'defaults api version to DEFAULT_API_VERSION' do
    expect(DIDWW::Client.api_version).to eq(DIDWW::Client::DEFAULT_API_VERSION)
  end

  it 'mode can only be :sandbox or :production' do
    DIDWW::Client.configure do |client|
      client.api_key = api_key
      DIDWW::Client.api_mode = :sandbox
      DIDWW::Client.api_mode = :production
      expect { DIDWW::Client.api_mode = :other }.to raise_error(ArgumentError)
    end
  end

  it 'applies customize_connection block to Faraday connection' do
    received_connection = nil
    DIDWW::Resource::Base.connection_object = nil
    DIDWW::Client.configure do |client|
      client.api_key = api_key
      client.customize_connection do |conn|
        received_connection = conn
      end
    end

    expect(received_connection).to be_a(JsonApiClient::Connection)
  end

  it 'configures without customize_connection block' do
    DIDWW::Client._customize_conn_block = nil
    DIDWW::Resource::Base.connection_object = nil
    expect {
      DIDWW::Client.configure do |client|
        client.api_key = api_key
      end
    }.not_to raise_error
  end

  it 'registers the bearer middleware on the JSON:API connection' do
    DIDWW::Resource::Base.connection_object = nil
    DIDWW::Client.configure { |client| client.api_key = api_key }

    expect(DIDWW::Resource::Base.connection.faraday.builder.handlers.map(&:klass)).to include(DIDWW::Auth::BearerMiddleware)
  end

  describe 'auth_base_url' do
    it 'points to the sandbox token service in sandbox mode' do
      DIDWW::Client.api_mode = :sandbox
      expect(DIDWW::Client.auth_base_url).to eq('https://auth-sandbox.didww.com')
    end

    it 'points to the production token service in production mode' do
      DIDWW::Client.api_mode = :production
      expect(DIDWW::Client.auth_base_url).to eq('https://auth.didww.com')
    end

    it 'is overridden by DIDWW_AUTH_URL' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('DIDWW_AUTH_URL').and_return('http://localhost:3001')
      expect(DIDWW::Client.auth_base_url).to eq('http://localhost:3001')
    end
  end

  describe 'prices_base_url' do
    it 'points to the sandbox hosts in sandbox mode' do
      DIDWW::Client.api_mode = :sandbox
      expect(DIDWW::Client.prices_base_url(:voice_in)).to eq('https://api-vin-sandbox.didww.com/v3/')
      expect(DIDWW::Client.prices_base_url(:voice_out)).to eq('https://api-vout-sandbox.didww.com/v3/')
      expect(DIDWW::Client.prices_base_url(:sms)).to eq('https://api-sms-sandbox.didww.com/v3/')
    end

    it 'points to the production hosts in production mode' do
      DIDWW::Client.api_mode = :production
      expect(DIDWW::Client.prices_base_url(:voice_in)).to eq('https://api-vin.didww.com/v3/')
      expect(DIDWW::Client.prices_base_url(:voice_out)).to eq('https://api-vout.didww.com/v3/')
      expect(DIDWW::Client.prices_base_url(:sms)).to eq('https://api-sms.didww.com/v3/')
    end

    it 'is overridden per service by environment variables' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('DIDWW_API_VIN_URL').and_return('http://localhost:3002/v3/')
      allow(ENV).to receive(:[]).with('DIDWW_API_VOUT_URL').and_return('http://localhost:3003/v3/')
      allow(ENV).to receive(:[]).with('DIDWW_API_SMS_URL').and_return('http://localhost:3004/v3/')
      expect(DIDWW::Client.prices_base_url(:voice_in)).to eq('http://localhost:3002/v3/')
      expect(DIDWW::Client.prices_base_url(:voice_out)).to eq('http://localhost:3003/v3/')
      expect(DIDWW::Client.prices_base_url(:sms)).to eq('http://localhost:3004/v3/')
    end

    it 'raises KeyError for an unknown service' do
      expect { DIDWW::Client.prices_base_url(:fax) }.to raise_error(KeyError)
    end
  end

  describe 'prices_audience' do
    it 'is the production hostname of the service in every mode' do
      DIDWW::Client.api_mode = :sandbox
      expect(DIDWW::Client.prices_audience(:voice_in)).to eq('api-vin.didww.com')
      expect(DIDWW::Client.prices_audience(:voice_out)).to eq('api-vout.didww.com')
      expect(DIDWW::Client.prices_audience(:sms)).to eq('api-sms.didww.com')
    end
  end

  describe 'scope=' do
    it 'accepts nil, :read and :full' do
      DIDWW::Client.scope = :read
      expect(DIDWW::Client.scope).to eq(:read)
      DIDWW::Client.scope = :full
      expect(DIDWW::Client.scope).to eq(:full)
      DIDWW::Client.scope = nil
      expect(DIDWW::Client.scope).to be_nil
    end

    it 'rejects any other value' do
      expect { DIDWW::Client.scope = :write }.to raise_error(ArgumentError)
      expect { DIDWW::Client.scope = 'read' }.to raise_error(ArgumentError)
    end
  end

  describe 'api_version=' do
    it 'accepts a later date' do
      DIDWW::Client.api_version = '2099-01-01'
      expect(DIDWW::Client.api_version).to eq('2099-01-01')
    end

    it 'rejects a value that is not a YYYY-MM-DD date' do
      expect { DIDWW::Client.api_version = 'latest' }.to raise_error(ArgumentError, /YYYY-MM-DD/)
      expect { DIDWW::Client.api_version = nil }.to raise_error(ArgumentError, /YYYY-MM-DD/)
    end

    it 'rejects a version earlier than DEFAULT_API_VERSION and points to didww-v3 6.x' do
      expect { DIDWW::Client.api_version = '2026-04-16' }.to raise_error(ArgumentError, /didww-v3 6\.x/)
      expect(DIDWW::Client.api_version).to eq(DIDWW::Client::DEFAULT_API_VERSION)
    end
  end

  describe 'with_api_version' do
    it 'overrides the version inside the block and restores it afterwards' do
      DIDWW::Client.with_api_version('2099-01-01') do
        expect(DIDWW::Client.api_version).to eq('2099-01-01')
      end
      expect(DIDWW::Client.api_version).to eq(DIDWW::Client::DEFAULT_API_VERSION)
    end

    it 'restores the version when the block raises' do
      expect {
        DIDWW::Client.with_api_version('2099-01-01') { raise 'boom' }
      }.to raise_error(RuntimeError, 'boom')
      expect(DIDWW::Client.api_version).to eq(DIDWW::Client::DEFAULT_API_VERSION)
    end

    it 'rejects a version earlier than DEFAULT_API_VERSION without yielding' do
      yielded = false
      expect { DIDWW::Client.with_api_version('2026-04-16') { yielded = true } }.to raise_error(ArgumentError, /didww-v3 6\.x/)
      expect(yielded).to be(false)
      expect(DIDWW::Client.api_version).to eq(DIDWW::Client::DEFAULT_API_VERSION)
    end

    it 'is visible only to the calling thread' do
      inside = Queue.new
      release = Queue.new
      thread = Thread.new do
        DIDWW::Client.with_api_version('2099-01-01') do
          inside << DIDWW::Client.api_version
          release.pop
        end
      end

      expect(inside.pop).to eq('2099-01-01')
      expect(DIDWW::Client.api_version).to eq(DIDWW::Client::DEFAULT_API_VERSION)
      release << true
      thread.join
    end
  end

  describe 'customize_faraday' do
    it 'applies the block to SDK-built Faraday connections' do
      received_connection = nil
      DIDWW::Client.customize_faraday { |conn| received_connection = conn }

      connection = DIDWW::Http.connection(DIDWW::Client.auth_base_url)
      expect(received_connection).to equal(connection)
    end
  end

  describe 'resource accessors' do
    it 'exposes SMS trunks and SMS trunk groups' do
      expect(DIDWW::Client).to respond_to(:sms_trunks)
      expect(DIDWW::Client).to respond_to(:sms_trunk_groups)
    end

    it 'no longer exposes DID group types and POPs' do
      expect(DIDWW::Client).not_to respond_to(:did_group_types)
      expect(DIDWW::Client).not_to respond_to(:pops)
      expect(defined?(DIDWW::Resource::DidGroupType)).to be_nil
      expect(defined?(DIDWW::Resource::Pop)).to be_nil
    end
  end

  describe 'prices accessors' do
    {
      voice_in_prices: :voice_in,
      voice_out_prices: :voice_out,
      sms_out_a2p_prices: :sms_out_a2p,
      sms_out_p2p_prices: :sms_out_p2p,
      sms_out_otp_prices: :sms_out_otp,
      sms_in_prices: :sms_in
    }.each do |accessor, service|
      it "#{accessor} delegates to DIDWW::Prices.#{service}" do
        prices_service = double('prices service')
        allow(DIDWW::Prices).to receive(service).and_return(prices_service)
        expect(DIDWW::Client.public_send(accessor)).to equal(prices_service)
      end
    end
  end
end
