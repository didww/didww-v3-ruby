# frozen_string_literal: true
RSpec.describe DIDWW::Resource::City do
  let (:client) { DIDWW::Client }

  describe 'GET /cities/:id' do
    let (:id) { 'cdf449bc-e3fb-42cc-bf31-b88f91e40de4' }

    context 'when City exists' do
      let (:city) do
        stub_didww_request(:get, "/cities/#{id}").to_return(
          status: 200,
          body: api_fixture('cities/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.cities.find(id).first
      end

      it 'returns a single City' do
        expect(city).to be_kind_of(DIDWW::Resource::City)
        expect(city.id).to eq(id)
      end
      it 'the City has "name", type: String' do
        expect(city.name).to be_kind_of(String)
      end
    end

    context 'when City does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/cities/#{id}").to_return(
          status: 404,
          body: api_fixture('cities/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.cities.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes Country' do
      stub_didww_request(:get, "/cities/#{id}?include=country").to_return(
        status: 200,
        body: api_fixture('cities/id/get/with_included_country/200'),
        headers: json_api_headers
      )
      city = client.cities.includes(:country).find(id).first
      expect(city.country).to be_kind_of(DIDWW::Resource::Country)
    end
  end

  describe 'GET /cities' do
    it 'returns a collection of Cities' do
      stub_didww_request(:get, '/cities').to_return(
        status: 200,
        body: api_fixture('cities/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.cities.all).to all be_an_instance_of(DIDWW::Resource::City)
    end
    it 'optionally includes Countries' do
      stub_didww_request(:get, '/cities?include=country').to_return(
        status: 200,
        body: api_fixture('cities/get/with_included_country/200'),
        headers: json_api_headers
      )
      expect(client.cities.includes(:country).all.first.country).to be_kind_of(DIDWW::Resource::Country)
    end
  end

end
