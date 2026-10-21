# frozen_string_literal: true
require 'active_support/cache'

RSpec.describe DIDWW::Auth::TokenProvider do
  subject(:provider) { described_class.new(sleeper: sleeper, clock: clock) }

  let(:sleeps) { [] }
  let(:sleeper) { ->(seconds) { sleeps << seconds } }
  let(:clock) { Struct.new(:now) { def call; now; end }.new(100.0) }
  let(:log) { StringIO.new }
  let(:audience) { DIDWW::Client::API_AUDIENCE }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  before { DIDWW::Client.logger = Logger.new(log) }

  describe '#token_for' do
    it 'mints a token for the audience and the default API version without a scope' do
      provider.token_for(audience)

      expect(
        a_request(:post, token_uri).with(
          body: { aud: [audience], api_version: DIDWW::Client::DEFAULT_API_VERSION },
          headers: { 'Api-Key' => StubRequestHelper::TEST_API_KEY, 'Content-Type' => 'application/json' }
        )
      ).to have_been_made.once
    end

    it 'logs nothing when the grant matches the request' do
      provider.token_for(audience)

      expect(log.string).to be_empty
    end

    it 'uses a shorter read timeout than API traffic' do
      allow(DIDWW::Http).to receive(:connection).and_call_original

      provider.token_for(audience)

      expect(DIDWW::Http).to have_received(:connection).with(DIDWW::Client.auth_base_url, timeout: 10)
    end

    it 'returns the granted values' do
      token = provider.token_for(audience)

      expect(token).to have_attributes(
        access_token: StubRequestHelper::TEST_ACCESS_TOKEN,
        token_type: 'Bearer',
        expires_in: 900,
        aud: [audience],
        scope: 'full',
        api_version: DIDWW::Client::DEFAULT_API_VERSION
      )
    end

    it 'does not expose the access token in #inspect' do
      expect(provider.token_for(audience).inspect).not_to include(StubRequestHelper::TEST_ACCESS_TOKEN)
    end

    it 'reuses the cached token' do
      first = provider.token_for(audience)
      second = provider.token_for(audience)

      expect(second.access_token).to eq(first.access_token)
      expect(a_request(:post, token_uri)).to have_been_made.once
    end

    it 'mints separately per audience' do
      stub_didww_token(aud: 'api-sms.didww.com')

      provider.token_for(audience)
      provider.token_for('api-sms.didww.com')

      expect(a_request(:post, token_uri).with(body: hash_including(aud: [audience]))).to have_been_made.once
      expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-sms.didww.com']))).to have_been_made.once
    end

    it 'mints separately per API version' do
      stub_didww_token(api_version: '2099-01-01')

      provider.token_for(audience)
      token = DIDWW::Client.with_api_version('2099-01-01') { provider.token_for(audience) }

      expect(token.api_version).to eq('2099-01-01')
      expect(a_request(:post, token_uri)).to have_been_made.twice
    end

    it 'mints separately per API key' do
      provider.token_for(audience)
      DIDWW::Client.api_key = 'another-key'
      stub_request(:post, token_uri)
        .with(headers: { 'Api-Key' => 'another-key' })
        .to_return(status: 200, body: token_body(access_token: 'another-token').to_json, headers: json_headers)

      expect(provider.token_for(audience).access_token).to eq('another-token')
    end

    it 'caches the token for the granted lifetime' do
      stub_didww_token(response: token_body(expires_in: 300))
      allow(DIDWW::Client.token_store).to receive(:write).and_call_original

      provider.token_for(audience)

      expect(DIDWW::Client.token_store).to have_received(:write).with(
        a_string_starting_with(described_class::CACHE_KEY_PREFIX),
        hash_including('access_token' => StubRequestHelper::TEST_ACCESS_TOKEN),
        expires_in: 300
      )
    end

    it 'mints again once the store expires the token' do
      DIDWW::Client.token_store = DIDWW::Auth::MemoryStore.new(clock: clock)
      stub_didww_token(response: token_body(expires_in: 300))

      provider.token_for(audience)
      clock.now += 299
      provider.token_for(audience)
      expect(a_request(:post, token_uri)).to have_been_made.once

      clock.now += 1
      provider.token_for(audience)
      expect(a_request(:post, token_uri)).to have_been_made.twice
    end

    it 'shares tokens through an external store' do
      DIDWW::Client.token_store = ActiveSupport::Cache::MemoryStore.new

      provider.token_for(audience)
      token = described_class.new(sleeper: sleeper, clock: clock).token_for(audience)

      expect(token.access_token).to eq(StubRequestHelper::TEST_ACCESS_TOKEN)
      expect(a_request(:post, token_uri)).to have_been_made.once
    end

    it 'mints once for concurrent callers' do
      stub_request(:post, token_uri).to_return do |_request|
        sleep(0.05)
        { status: 200, body: token_body.to_json, headers: json_headers }
      end

      tokens = Array.new(10) { Thread.new { provider.token_for(audience).access_token } }.map(&:value)

      expect(tokens.uniq).to eq([StubRequestHelper::TEST_ACCESS_TOKEN])
      expect(a_request(:post, token_uri)).to have_been_made.once
    end

    context 'when a scope is configured' do
      before { DIDWW::Client.scope = :read }

      it 'requests the scope' do
        stub_didww_token(scope: :read)

        provider.token_for(audience)

        expect(a_request(:post, token_uri).with(body: hash_including(scope: 'read'))).to have_been_made.once
      end

      it 'warns when the granted scope is wider and keeps the token' do
        stub_didww_token(scope: :read, response: token_body(scope: 'full'))

        token = provider.token_for(audience)

        expect(token.scope).to eq('full')
        expect(log.string).to include('requested read, granted full')
      end

      it 'logs nothing when the full scope is requested and granted' do
        DIDWW::Client.scope = :full
        stub_didww_token(scope: :full)

        provider.token_for(audience)

        expect(log.string).to be_empty
      end

      it 'mints separately from the default scope' do
        stub_didww_token(scope: :read)

        provider.token_for(audience)
        DIDWW::Client.scope = nil
        provider.token_for(audience)

        expect(a_request(:post, token_uri)).to have_been_made.twice
      end
    end

    it 'warns when the granted API version differs' do
      stub_didww_token(response: token_body(api_version: '2099-01-01'))

      provider.token_for(audience)

      expect(log.string).to include("requested #{DIDWW::Client::DEFAULT_API_VERSION}, granted 2099-01-01")
    end

    it 'raises InvalidGrant and caches nothing when the grant does not cover the audience' do
      stub_didww_token(response: token_body(aud: 'api-sms.didww.com'))

      expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::InvalidGrant)
      expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::InvalidGrant)
      expect(a_request(:post, token_uri)).to have_been_made.twice
    end

    it 'instruments the mint without the token or the key' do
      payloads = []
      callback = ->(_name, _started, _finished, _id, payload) { payloads << payload }

      ActiveSupport::Notifications.subscribed(callback, described_class::NOTIFICATION) { provider.token_for(audience) }

      expect(payloads).to eq(
        [
          {
            aud: [audience],
            scope_requested: nil,
            scope_granted: 'full',
            api_version: DIDWW::Client::DEFAULT_API_VERSION,
            expires_in: 900
          }
        ]
      )
    end

    it 'times the mint in the instrumentation event' do
      stub_request(:post, token_uri).to_return do |_request|
        sleep(0.05)
        { status: 200, body: token_body.to_json, headers: json_headers }
      end
      events = []
      callback = ->(event) { events << event }

      ActiveSupport::Notifications.subscribed(callback, described_class::NOTIFICATION) { provider.token_for(audience) }

      expect(events.size).to eq(1)
      expect(events.first.duration).to be >= 40
    end

    context 'when the token service refuses the key' do
      before do
        stub_didww_token(
          status: 401,
          response: { error: 'invalid_client', error_description: 'Client authentication failed.' }
        )
      end

      it 'raises InvalidClient without retrying' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::InvalidClient) { |error|
          expect(error).to have_attributes(status: 401, error: 'invalid_client', error_description: 'Client authentication failed.')
        }
        expect(a_request(:post, token_uri)).to have_been_made.once
        expect(sleeps).to be_empty
      end

      it 'instruments the failed mint with the exception' do
        payloads = []
        callback = ->(_name, _started, _finished, _id, payload) { payloads << payload }

        ActiveSupport::Notifications.subscribed(callback, described_class::NOTIFICATION) do
          expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::InvalidClient)
        end

        expect(payloads.size).to eq(1)
        expect(payloads.first.except(:exception_object)).to eq(
          aud: [audience],
          scope_requested: nil,
          exception: ['DIDWW::Auth::InvalidClient', 'invalid_client: Client authentication failed.']
        )
        expect(payloads.first[:exception_object]).to be_a(DIDWW::Auth::InvalidClient)
      end
    end

    context 'when the token service rejects the request' do
      before do
        stub_didww_token(
          status: 400,
          response: { error: 'invalid_scope', error_description: 'scope is not a known scope' }
        )
      end

      it 'raises InvalidRequest' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::InvalidRequest) { |error|
          expect(error).to have_attributes(status: 400, error: 'invalid_scope', error_description: 'scope is not a known scope')
        }
        expect(a_request(:post, token_uri)).to have_been_made.once
      end
    end

    context 'when the token service rate-limits the caller' do
      before do
        stub_didww_token(
          status: 429,
          response: { error: 'rate_limit_exceeded', error_description: 'Too many token requests from this address.' },
          headers: { 'Retry-After' => '30' }
        ).then.to_return(status: 200, body: token_body.to_json, headers: json_headers)
      end

      it 'raises RateLimited with retry_after' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited) { |error|
          expect(error).to have_attributes(status: 429, retry_after: 30)
        }
      end

      it 'raises without a request while the window is open' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited)
        clock.now += 29

        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited) { |error|
          expect(error.retry_after).to eq(1)
        }
        expect(a_request(:post, token_uri)).to have_been_made.once
      end

      it 'instruments nothing while the window is open' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited)
        payloads = []
        callback = ->(_name, _started, _finished, _id, payload) { payloads << payload }

        ActiveSupport::Notifications.subscribed(callback, described_class::NOTIFICATION) do
          expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited)
        end

        expect(payloads).to eq([])
      end

      it 'mints again once the window has passed' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited)
        clock.now += 30

        expect(provider.token_for(audience).access_token).to eq(StubRequestHelper::TEST_ACCESS_TOKEN)
        expect(a_request(:post, token_uri)).to have_been_made.twice
      end

      it 'does not sleep' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited)
        expect(sleeps).to be_empty
      end

      it 'raises without a request for every audience while the window is open' do
        stub_didww_token(aud: 'api-vin.didww.com')

        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::RateLimited)
        expect { provider.token_for('api-vin.didww.com') }.to raise_error(DIDWW::Auth::RateLimited)
        expect(a_request(:post, token_uri)).to have_been_made.once
      end
    end

    context 'when the token service fails transiently' do
      before do
        stub_didww_token(status: 503, response: { error: 'server_error' })
          .times(3)
          .then.to_return(status: 200, body: token_body.to_json, headers: json_headers)
      end

      it 'retries with an exponential backoff' do
        allow(provider).to receive(:rand).and_return(1.0)

        expect(provider.token_for(audience).access_token).to eq(StubRequestHelper::TEST_ACCESS_TOKEN)
        expect(a_request(:post, token_uri)).to have_been_made.times(4)
        expect(sleeps).to eq([1.0, 2.0, 4.0])
      end

      it 'scales each delay by the jitter' do
        allow(provider).to receive(:rand).and_return(0.5)

        provider.token_for(audience)

        expect(sleeps).to eq([0.5, 1.0, 2.0])
      end
    end

    context 'when the backoff reaches its ceiling' do
      before do
        stub_const("#{described_class}::MAX_ATTEMPTS", 6)
        stub_didww_token(status: 503, response: { error: 'server_error' })
          .times(5)
          .then.to_return(status: 200, body: token_body.to_json, headers: json_headers)
        allow(provider).to receive(:rand).and_return(1.0)
      end

      it 'caps the delay' do
        provider.token_for(audience)

        expect(sleeps).to eq([1.0, 2.0, 4.0, 8.0, 8.0])
      end
    end

    context 'when the token service keeps failing' do
      before { stub_didww_token(status: 500, response: { error: 'server_error' }) }

      it 'raises ServerError after the last attempt' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::ServerError) { |error|
          expect(error).to have_attributes(status: 500, error: 'server_error')
        }
        expect(a_request(:post, token_uri)).to have_been_made.times(described_class::MAX_ATTEMPTS)
      end
    end

    context 'when the token service answers a 5xx without a JSON body' do
      before { stub_request(:post, token_uri).to_return(status: 502, body: '<html>Bad Gateway</html>') }

      it 'raises ServerError' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::ServerError) { |error|
          expect(error.status).to eq(502)
        }
      end
    end

    context 'when the token service cannot be reached' do
      before { stub_request(:post, token_uri).to_timeout }

      it 'raises ConnectionError after the last attempt' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::ConnectionError)
        expect(a_request(:post, token_uri)).to have_been_made.times(described_class::MAX_ATTEMPTS)
        expect(sleeps.size).to eq(described_class::MAX_ATTEMPTS - 1)
      end
    end

    context 'when the TLS handshake fails' do
      before { stub_request(:post, token_uri).to_raise(Faraday::SSLError.new('certificate verify failed')) }

      it 'raises ConnectionError without retrying' do
        expect { provider.token_for(audience) }.to raise_error(DIDWW::Auth::ConnectionError, 'certificate verify failed')
        expect(a_request(:post, token_uri)).to have_been_made.once
        expect(sleeps).to be_empty
      end
    end
  end

  describe 'a failed mint' do
    {
      DIDWW::Auth::ServerError => -> { { status: 500, body: { error: 'server_error' }.to_json } },
      DIDWW::Auth::ConnectionError => -> { raise Errno::ECONNREFUSED }
    }.each do |error_class, failure|
      context "when it raises #{error_class}" do
        it 'raises the same error to callers queued behind it without minting again' do
          gate = Queue.new
          stub_request(:post, token_uri).to_return do |_request|
            gate.pop
            failure.call
          end

          threads = Array.new(5) do
            Thread.new do
              provider.token_for(audience)
            rescue DIDWW::Auth::Error => e
              e
            end
          end
          sleep(0.01) while threads.any? { |thread| thread.status == 'run' }
          (threads.size * described_class::MAX_ATTEMPTS).times { gate << true }
          errors = threads.map(&:value)

          expect(errors).to all(be_an_instance_of(error_class))
          expect(errors).to all(be(errors.first))
          expect(a_request(:post, token_uri)).to have_been_made.times(described_class::MAX_ATTEMPTS)
        end

        it 'lets a later call mint again' do
          stub_request(:post, token_uri).to_return { |_request| failure.call }
            .times(described_class::MAX_ATTEMPTS)
            .then.to_return(status: 200, body: token_body.to_json, headers: json_headers)

          expect { provider.token_for(audience) }.to raise_error(error_class)
          expect(provider.token_for(audience).access_token).to eq(StubRequestHelper::TEST_ACCESS_TOKEN)
          expect(a_request(:post, token_uri)).to have_been_made.times(described_class::MAX_ATTEMPTS + 1)
        end
      end
    end
  end

  describe '#invalidate' do
    it 'evicts the cached token when it is the refused one' do
      stub_request(:post, token_uri)
        .to_return(status: 200, body: token_body(access_token: 'first-token').to_json, headers: json_headers)
        .then.to_return(status: 200, body: token_body(access_token: 'second-token').to_json, headers: json_headers)
      provider.token_for(audience)

      provider.invalidate(audience, 'first-token')

      expect(provider.token_for(audience).access_token).to eq('second-token')
    end

    it 'keeps a newer token than the refused one' do
      provider.token_for(audience)

      provider.invalidate(audience, 'stale-token')

      expect(provider.token_for(audience).access_token).to eq(StubRequestHelper::TEST_ACCESS_TOKEN)
      expect(a_request(:post, token_uri)).to have_been_made.once
    end
  end
end
