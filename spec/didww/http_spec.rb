# frozen_string_literal: true
RSpec.describe DIDWW::Http do
  describe '.connection' do
    let(:url) { 'https://api-vin-sandbox.didww.com/v3/' }

    it 'uses the default read timeout' do
      expect(described_class.connection(url).options.timeout).to eq(described_class::TIMEOUT)
    end

    it 'uses the given read timeout' do
      expect(described_class.connection(url, timeout: 10).options.timeout).to eq(10)
    end

    context 'when verbose logging is enabled' do
      before { DIDWW::Client.http_verbose = true }

      after { DIDWW::Client.http_verbose = false }

      def verbose_output
        original = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original
      end

      it 'filters the API key of a token request' do
        output = verbose_output { DIDWW::Client.token_provider.token_for(DIDWW::Client::API_AUDIENCE) }

        expect(output).to include('Api-Key: [FILTERED]')
        expect(output).not_to include(StubRequestHelper::TEST_API_KEY)
      end

      it 'filters an Authorization header' do
        stub_request(:get, "#{url}prices.csv.gz").to_return(status: 200, body: '')

        output = verbose_output { described_class.connection(url).get('prices.csv.gz', nil, 'Authorization' => 'Bearer secret-token') }

        expect(output).to include('Authorization: [FILTERED]')
        expect(output).not_to include('secret-token')
      end

      it 'keeps the bearer token out of the log' do
        stub_didww_token(aud: 'api-vin.didww.com', response: token_body(aud: 'api-vin.didww.com', access_token: 'vin-token'))
        stub_request(:get, "#{url}prices.csv.gz").with(headers: { 'Authorization' => 'Bearer vin-token' }).to_return(status: 200, body: '')

        output = verbose_output { described_class.connection(url, audience: 'api-vin.didww.com').get('prices.csv.gz') }

        expect(output).to include('request: GET')
        expect(output).not_to include('vin-token')
      end
    end
  end
end
