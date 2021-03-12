# frozen_string_literal: true
module StubRequestHelper
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
      'User-Agent' => /didww-v3 Ruby gem v\d+\.\d+\.\d+/
    }
  end
end
