# frozen_string_literal: true
module StubRequestHelper
  TEST_API_KEY = 'test-key'
  TEST_ACCESS_TOKEN = 'test-access-token'

  # stub_request shortcut
  def stub_didww_request(method, uri)
    stub_request(method, api_uri(uri)).with(headers: request_headers)
  end

  def api_uri(uri)
    [DIDWW::Client.api_base_url.chomp('/'), uri].join
  end

  # fixture file body shortcut
  def api_fixture(path, ext: :json)
    File.read("spec/fixtures/#{path}.#{ext.to_s}")
  end

  def json_api_headers
    { 'Content-Type' => 'application/vnd.api+json' }
  end

  def request_headers
    {
      'Content-Type' => 'application/vnd.api+json',
      'User-Agent' => /didww-v3 Ruby gem v\d+\.\d+\.\d+/,
      'Authorization' => "Bearer #{TEST_ACCESS_TOKEN}"
    }
  end

  def token_uri
    "#{DIDWW::Client.auth_base_url}/token"
  end

  def token_body(aud: DIDWW::Client::API_AUDIENCE, scope: 'full', api_version: DIDWW::Client::DEFAULT_API_VERSION, access_token: TEST_ACCESS_TOKEN, expires_in: 900)
    {
      access_token: access_token,
      token_type: 'Bearer',
      expires_in: expires_in,
      aud: [aud],
      scope: scope,
      api_version: api_version
    }
  end

  # Stubs POST /token for one audience. The default response grants exactly what was requested.
  def stub_didww_token(aud: DIDWW::Client::API_AUDIENCE, scope: nil, api_version: DIDWW::Client::DEFAULT_API_VERSION, status: 200, response: nil, headers: {})
    request_body = { aud: [aud], api_version: api_version }
    request_body[:scope] = scope.to_s if scope
    response ||= token_body(aud: aud, scope: (scope || :full).to_s, api_version: api_version)
    stub_request(:post, token_uri)
      .with(body: hash_including(request_body), headers: { 'Api-Key' => TEST_API_KEY })
      .to_return(status: status, body: response.to_json, headers: { 'Content-Type' => 'application/json' }.merge(headers))
  end

  def prices_uri(service, path)
    [DIDWW::Client.prices_base_url(service).chomp('/'), path].join
  end

  def stub_prices_request(service, method, path)
    stub_request(method, prices_uri(service, path)).with(headers: prices_request_headers)
  end

  def prices_request_headers
    {
      'User-Agent' => /didww-v3 Ruby gem v\d+\.\d+\.\d+/,
      'Authorization' => "Bearer #{TEST_ACCESS_TOKEN}"
    }
  end
end
