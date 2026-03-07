# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Area do
  let(:client) { DIDWW::Client }

  describe 'GET /areas' do
    it 'returns a collection of Areas' do
      stub_didww_request(:get, '/areas').to_return(
        status: 200,
        body: api_fixture('areas/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.areas.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'GET /areas/{id}' do
    let(:id) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

    it 'returns a single Area' do
      stub_didww_request(:get, "/areas/#{id}").to_return(
        status: 200,
        body: api_fixture('areas/id/get/without_includes/200'),
        headers: json_api_headers
      )
      area = client.areas.find(id).first
      expect(area).to be_kind_of(described_class)
      expect(area.id).to eq(id)
      expect(area.name).to be_kind_of(String)
    end
  end
end
