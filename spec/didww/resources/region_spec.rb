# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Region do
  let (:client) { DIDWW::Client }

  describe 'GET /regions/:id' do
    let (:id) { '8ce33ee2-73da-4baa-85a0-cd607d0e9733' }

    context 'when Region exists' do
      let (:region) do
        stub_didww_request(:get, "/regions/#{id}").to_return(
          status: 200,
          body: api_fixture('regions/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.regions.find(id).first
      end

      it 'returns a single Region' do
        expect(region).to be_kind_of(DIDWW::Resource::Region)
        expect(region.id).to eq(id)
      end
      it 'the Region has "name", type: String' do
        expect(region.name).to be_kind_of(String)
      end
    end

    context 'when Region does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/regions/#{id}").to_return(
          status: 404,
          body: api_fixture('regions/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.regions.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes Country' do
      stub_didww_request(:get, "/regions/#{id}?include=country").to_return(
        status: 200,
        body: api_fixture('regions/id/get/sample_2/200'),
        headers: json_api_headers
      )
      region = client.regions.includes(:country).find(id).first
      expect(region.country).to be_kind_of(DIDWW::Resource::Country)
    end
  end

  describe 'GET /regions' do
    it 'returns a collection of Regions' do
      stub_didww_request(:get, '/regions').to_return(
        status: 200,
        body: api_fixture('regions/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.regions.all).to all be_an_instance_of(DIDWW::Resource::Region)
    end
    it 'optionally includes Countries' do
      stub_didww_request(:get, '/regions?include=country').to_return(
        status: 200,
        body: api_fixture('regions/get/sample_2/200'),
        headers: json_api_headers
      )
      expect(client.regions.includes(:country).all.first.country).to be_kind_of(DIDWW::Resource::Country)
    end
  end

end
