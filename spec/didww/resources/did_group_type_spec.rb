# frozen_string_literal: true
RSpec.describe DIDWW::Resource::DidGroupType do
  let (:client) { DIDWW::Client }

  describe 'GET /did_group_types/:id' do
    let (:id) { '4e057223-2a0a-4707-8b35-4e6ef96c9dd9' }

    context 'when DidGroupType exists' do
      let (:did_group_type) do
        stub_didww_request(:get, "/did_group_types/#{id}").to_return(
          status: 200,
          body: api_fixture('did_group_types/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.did_group_types.find(id).first
      end

      it 'returns a single DidGroupType' do
        expect(did_group_type).to be_kind_of(DIDWW::Resource::DidGroupType)
        expect(did_group_type.id).to eq(id)
      end
      it 'the DidGroupType has "name", type: String' do
        expect(did_group_type.name).to be_kind_of(String)
      end
    end

    context 'when DidGroupType does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/did_group_types/#{id}").to_return(
          status: 404,
          body: api_fixture('did_group_types/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.did_group_types.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'GET /did_group_types' do
    it 'returns a collection of DidGroupTypes' do
      stub_didww_request(:get, '/did_group_types').to_return(
        status: 200,
        body: api_fixture('did_group_types/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.did_group_types.all).to be_a_list_of(DIDWW::Resource::DidGroupType)
    end
  end

end
