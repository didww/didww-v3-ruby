# frozen_string_literal: true
RSpec.describe DIDWW::Auth::BearerMiddleware do
  let(:json_headers) { { 'Content-Type' => 'application/json' } }
  let(:unauthorized_body) do
    { errors: [{ title: 'Unauthorized', detail: 'Authorization failed', code: '401', status: '401' }] }.to_json
  end
  let(:unauthorized_headers) { json_api_headers.merge('WWW-Authenticate' => 'Bearer error="invalid_token"') }

  before do
    stub_request(:post, token_uri)
      .to_return(status: 200, body: token_body(access_token: 'first-token').to_json, headers: json_headers)
      .then.to_return(status: 200, body: token_body(access_token: 'second-token').to_json, headers: json_headers)
      .then.to_return(status: 200, body: token_body(access_token: 'third-token').to_json, headers: json_headers)
  end

  describe 'JSON:API requests' do
    it 'sends a bearer token and neither Api-Key nor X-DIDWW-API-Version' do
      stub = stub_request(:get, api_uri('/countries'))
        .with(headers: { 'Authorization' => 'Bearer first-token' }) { |req| (req.headers.keys.map(&:downcase) & ['api-key', 'x-didww-api-version']).empty? }
        .to_return(status: 200, body: api_fixture('countries/get/without_includes/200'), headers: json_api_headers)

      DIDWW::Client.countries.all

      expect(stub).to have_been_requested.once
    end

    it 'mints a new token and retries once when the token is refused' do
      stub_request(:get, api_uri('/countries'))
        .with(headers: { 'Authorization' => 'Bearer first-token' })
        .to_return(status: 401, body: unauthorized_body, headers: unauthorized_headers)
      stub_request(:get, api_uri('/countries'))
        .with(headers: { 'Authorization' => 'Bearer second-token' })
        .to_return(status: 200, body: api_fixture('countries/get/without_includes/200'), headers: json_api_headers)

      expect(DIDWW::Client.countries.all).to all be_an_instance_of(DIDWW::Resource::Country)
      expect(a_request(:post, token_uri)).to have_been_made.twice
      expect(a_request(:get, api_uri('/countries'))).to have_been_made.twice
    end

    it 'replays the same body when a PATCH is retried' do
      id = '21e02b15-806d-44b3-b67f-434ea6c44f61'
      body = json_api_body(id: id, type: 'exports', attributes: { external_reference_id: 'renamed-ref-99' })
      stub_request(:patch, api_uri("/exports/#{id}"))
        .to_return(status: 401, body: unauthorized_body, headers: unauthorized_headers)
        .then.to_return(status: 200, body: api_fixture('exports/id/patch/update_external_reference_id/200'), headers: json_api_headers)

      export = DIDWW::Resource::Export.load(id: id)
      export.external_reference_id = 'renamed-ref-99'

      expect(export.save).to eq(true)
      expect(a_request(:patch, api_uri("/exports/#{id}")).with(body: body, headers: { 'Authorization' => 'Bearer first-token' })).to have_been_made.once
      expect(a_request(:patch, api_uri("/exports/#{id}")).with(body: body, headers: { 'Authorization' => 'Bearer second-token' })).to have_been_made.once
    end

    it 'raises NotAuthorized when the new token is refused too' do
      stub_request(:get, api_uri('/countries')).to_return(status: 401, body: unauthorized_body, headers: unauthorized_headers)

      expect { DIDWW::Client.countries.all }.to raise_error(JsonApiClient::Errors::NotAuthorized)
      expect(a_request(:get, api_uri('/countries'))).to have_been_made.twice
      expect(a_request(:post, token_uri)).to have_been_made.twice
    end

    it 'raises AccessDenied on insufficient scope without minting again' do
      stub_request(:get, api_uri('/countries')).to_return(
        status: 403,
        body: { errors: [{ title: 'Insufficient scope', code: '403', status: '403' }] }.to_json,
        headers: json_api_headers.merge('WWW-Authenticate' => 'Bearer error="insufficient_scope"')
      )

      expect { DIDWW::Client.countries.all }.to raise_error(JsonApiClient::Errors::AccessDenied)
      expect(a_request(:get, api_uri('/countries'))).to have_been_made.once
      expect(a_request(:post, token_uri)).to have_been_made.once
    end

    it 'keeps a token another caller minted after the refused one' do
      provider = DIDWW::Client.token_provider
      stub_request(:get, api_uri('/countries'))
        .with(headers: { 'Authorization' => 'Bearer first-token' })
        .to_return do |_request|
          provider.invalidate(DIDWW::Client::API_AUDIENCE, 'first-token')
          provider.token_for(DIDWW::Client::API_AUDIENCE)
          { status: 401, body: unauthorized_body, headers: unauthorized_headers }
        end
      stub_request(:get, api_uri('/countries'))
        .with(headers: { 'Authorization' => 'Bearer second-token' })
        .to_return(status: 200, body: api_fixture('countries/get/without_includes/200'), headers: json_api_headers)

      DIDWW::Client.countries.all

      expect(a_request(:post, token_uri)).to have_been_made.twice
    end
  end

  describe 'connections built by DIDWW::Http' do
    let(:url) { 'https://api-vin-sandbox.didww.com/v3/' }
    let(:connection) { DIDWW::Http.connection(url, audience: 'api-vin.didww.com') }

    before do
      stub_didww_token(aud: 'api-vin.didww.com', response: token_body(aud: 'api-vin.didww.com', access_token: 'vin-token'))
    end

    it 'mints a token for the configured audience' do
      stub = stub_request(:get, "#{url}prices.csv.gz")
        .with(headers: { 'Authorization' => 'Bearer vin-token' })
        .to_return(status: 200, body: '')

      connection.get('prices.csv.gz')

      expect(stub).to have_been_requested.once
      expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-vin.didww.com']))).to have_been_made.once
    end

    it 'never sends If-None-Match' do
      stub = stub_request(:get, "#{url}prices.csv.gz")
        .with { |req| !req.headers.keys.map(&:downcase).include?('if-none-match') }
        .to_return(status: 304, body: '')

      connection.get('prices.csv.gz', nil, 'If-None-Match' => '"abc"', 'If-Modified-Since' => 'Wed, 14 Oct 2026 06:00:00 GMT')

      expect(stub).to have_been_requested.once
    end
  end
end
