# frozen_string_literal: true

RSpec.describe DIDWW::Resource::NanpaPrefix do
  let(:client) { DIDWW::Client }

  describe 'GET /nanpa_prefixes/{id}' do
    context 'when NANPA prefix exists' do
      let(:id) { 'a1ad26e5-1413-4edc-862b-1075378b6034' }

      before do
        stub_didww_request(:get, "/nanpa_prefixes/#{id}").to_return(
          status: 200,
          body: api_fixture('nanpa_prefixes/id/get/without_includes/200'),
          headers: json_api_headers
        )
      end

      it 'returns a instance of NANPA prefix' do
        expect(client.nanpa_prefixes.load(id: id)).to be_instance_of(DIDWW::Resource::NanpaPrefix)
      end
    end
  end

  describe 'GET /nanpa_prefixes' do
    context 'when valid request' do
      before do
        stub_didww_request(:get, '/nanpa_prefixes').to_return(
          status: 200,
          body: api_fixture('nanpa_prefixes/get/without_includes/200'),
          headers: json_api_headers
        )
      end

      it 'returns a collection of NANPA prefixes' do
        expect(client.nanpa_prefixes.all).to all be_an_instance_of(DIDWW::Resource::NanpaPrefix)
      end
    end

    context 'when include by country' do
      before do
        stub_didww_request(:get, '/nanpa_prefixes?include=country').to_return(
          status: 200,
          body: api_fixture('nanpa_prefixes/get/include/country'),
          headers: json_api_headers
        )
      end

      it 'returns a instance of Country' do
        expect(client.nanpa_prefixes.includes(:country).all.first.country).to be_instance_of(DIDWW::Resource::Country)
      end
    end

    context 'when include by region' do
      before do
        stub_didww_request(:get, '/nanpa_prefixes?include=region').to_return(
          status: 200,
          body: api_fixture('nanpa_prefixes/get/include/region'),
          headers: json_api_headers
        )
      end

      it 'returns a instance of Region' do
        expect(client.nanpa_prefixes.includes(:region).all.first.region).to be_instance_of(DIDWW::Resource::Region)
      end
    end

    context 'when include by all relationships' do
      before do
        stub_didww_request(:get, '/nanpa_prefixes?include=region,country').to_return(
          status: 200,
          body: api_fixture('nanpa_prefixes/get/include/region_country'),
          headers: json_api_headers
        )
      end

      it 'returns a instance of Region' do
        expect(client.nanpa_prefixes.includes(:region, :country).all.first.region).to be_instance_of(DIDWW::Resource::Region)
      end

      it 'returns a instance of Country' do
        expect(client.nanpa_prefixes.includes(:region, :country).all.first.country).to be_instance_of(DIDWW::Resource::Country)
      end
    end
  end
end
