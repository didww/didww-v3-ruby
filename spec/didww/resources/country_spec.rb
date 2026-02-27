# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Country do
  let (:client) { DIDWW::Client }

  describe 'GET /countries/:id' do
    let (:id) { 'e352699c-3764-415b-8946-dd470c1e0ed7' }

    context 'when Country exists' do
      let (:country) do
        stub_didww_request(:get, "/countries/#{id}").to_return(
          status: 200,
          body: api_fixture('countries/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.countries.find(id).first
      end

      it 'returns a single Country' do
        expect(country).to be_kind_of(DIDWW::Resource::Country)
        expect(country.id).to eq(id)
      end
      it 'the Country has "name", type: String' do
        expect(country.name).to be_kind_of(String)
      end
      it 'the Country has "prefix", type: String' do
        expect(country.prefix).to be_kind_of(String)
      end
      it 'the Country has "iso", type: String' do
        expect(country.iso).to be_kind_of(String)
      end
    end

    it 'optionally includes Regions' do
      stub_didww_request(:get, "/countries/#{id}?include=regions").to_return(
        status: 200,
        body: api_fixture('countries/id/get/sample_2/200'),
        headers: json_api_headers
      )
      country = client.countries.includes(:regions).find(id).first
      expect(country.regions).to all be_an_instance_of(DIDWW::Resource::Region)
      expect(country.regions.length).to eq(10)
    end

    context 'when Country does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/countries/#{id}").to_return(
          status: 404,
          body: api_fixture('countries/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.countries.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'GET /countries' do
    it 'returns a collection of Countries' do
      stub_didww_request(:get, '/countries').to_return(
        status: 200,
        body: api_fixture('countries/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.countries.all).to all be_an_instance_of(DIDWW::Resource::Country)
    end
  end

end
