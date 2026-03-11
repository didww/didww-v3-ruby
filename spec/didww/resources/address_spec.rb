# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Address do
  let(:client) { DIDWW::Client }

  describe 'GET /addresses' do
    it 'returns a collection of Addresses' do
      stub_didww_request(:get, '/addresses').to_return(
        status: 200,
        body: api_fixture('addresses/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.addresses.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'has correct attributes' do
    let(:address) do
      stub_didww_request(:get, '/addresses').to_return(
        status: 200,
        body: api_fixture('addresses/get/without_includes/200'),
        headers: json_api_headers
      )
      client.addresses.all.first
    end

    it '"city_name", type: String' do
      expect(address.city_name).to be_kind_of(String)
    end

    it '"postal_code", type: String' do
      expect(address.postal_code).to be_kind_of(String)
    end

    it '"address", type: String' do
      expect(address.address).to be_kind_of(String)
    end

    it '"created_at", type: Time' do
      expect(address.created_at).to be_kind_of(Time)
    end

    it '"verified", type: Boolean' do
      expect(address.verified).to eq(false).or eq(true)
    end
  end
end
