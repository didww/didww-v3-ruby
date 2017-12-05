module StubRequestHelper
  # stub_request shortcut
  def stub_didww_request(method, uri)
    stub_request(method, api_uri(uri))
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
end
