# frozen_string_literal: true
RSpec.describe DIDWW::Resource::PublicKey do
  describe 'GET /public_keys' do
    it 'returns a collection of PublicKeys' do
      stub_didww_request(:get, '/public_keys').to_return(
        status: 200,
        body: api_fixture('public_keys/get/without_includes/200'),
        headers: json_api_headers
      )
      keys = DIDWW::Resource::PublicKey.all
      expect(keys).to all be_an_instance_of(described_class)
      expect(keys.length).to eq(2)
    end
  end

  describe 'request headers' do
    it 'does not send Api-Key header' do
      stub = stub_request(:get, api_uri('/public_keys'))
        .with { |req| !req.headers.key?('Api-Key') }
        .to_return(
          status: 200,
          body: api_fixture('public_keys/get/without_includes/200'),
          headers: json_api_headers
        )
      DIDWW::Resource::PublicKey.all
      expect(stub).to have_been_requested
    end
  end

  describe 'has correct attributes' do
    let(:public_key) do
      stub_didww_request(:get, '/public_keys').to_return(
        status: 200,
        body: api_fixture('public_keys/get/without_includes/200'),
        headers: json_api_headers
      )
      DIDWW::Resource::PublicKey.all.first
    end

    it '"key", type: String' do
      expect(public_key.key).to be_kind_of(String)
      expect(public_key.key).to include('BEGIN PUBLIC KEY')
    end
  end
end
