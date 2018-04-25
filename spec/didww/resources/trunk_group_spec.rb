RSpec.describe DIDWW::Resource::TrunkGroup do
  let (:client) { DIDWW::Client }

  describe 'GET /trunk_groups/{id}' do
    let (:id) { '418fe352-04b8-4e03-a7ce-cb57efd8c664' }

    context 'when TrunkGroup exists' do
      let (:trunk_group) do
        stub_didww_request(:get, "/trunk_groups/#{id}").to_return(
          status: 200,
          body: api_fixture('trunk_groups/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.trunk_groups.find(id).first
      end

      it 'returns a single TrunkGroup' do
        expect(trunk_group).to be_kind_of(DIDWW::Resource::TrunkGroup)
        expect(trunk_group.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"name", type: String' do
          expect(trunk_group.name).to be_kind_of(String)
        end
        it '"capacity_limit", type: Integer' do
          expect(trunk_group.capacity_limit).to be_kind_of(Integer)
        end
        it '"created_at", type: Time' do
          expect(trunk_group.created_at).to be_kind_of(Time)
        end
      end

      describe '#trunks_count' do
        it 'reads trunks_count form meta' do
          expect(trunk_group).to receive(:meta).and_call_original
          expect(trunk_group.trunks_count).to eq(1)
        end
      end

      it 'has Trunks relationship' do
        expect(trunk_group.relationships[:trunks]).to be
      end

      it 'lazily fetches Trunks' do
        request = stub_request(:get, trunk_group.relationships.trunks[:links][:related]).to_return(
            status: 200,
            body: api_fixture('trunks/get/sample_1/200'),
            headers: json_api_headers
          )
        expect(trunk_group.trunks).to be_a_list_of(DIDWW::Resource::Trunk)
        expect(request).to have_been_made.once
      end

    end

    context 'when TrunkGroup does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/trunk_groups/#{id}").to_return(
          status: 404,
          body: api_fixture('trunk_groups/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.trunk_groups.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes Trunk' do
      stub_didww_request(:get, "/trunk_groups/#{id}?include=trunks").to_return(
        status: 200,
        body: api_fixture('trunk_groups/id/get/sample_2/200'),
        headers: json_api_headers
      )
      trunk_group = client.trunk_groups.includes(:trunks).find(id).first
      expect(trunk_group.trunks).to be_a_list_of(DIDWW::Resource::Trunk)
    end
  end

  describe 'GET /trunk_groups' do
    it 'returns a collection of TrunkGroups' do
      stub_didww_request(:get, '/trunk_groups').to_return(
        status: 200,
        body: api_fixture('trunk_groups/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.trunk_groups.all).to be_a_list_of(DIDWW::Resource::TrunkGroup)
    end
    it 'optionally includes Trunks' do
      stub_didww_request(:get, '/trunk_groups?include=trunks').to_return(
        status: 200,
        body: api_fixture('trunk_groups/get/sample_2/200'),
        headers: json_api_headers
      )
      expect(client.trunk_groups.includes(:trunks).all.first.trunks).to be_a_list_of(DIDWW::Resource::Trunk)
    end

  end

  describe 'POST /trunk_groups' do
    describe 'with correct attributes' do
      it 'creates a TrunkGroup' do
        stub_didww_request(:post, '/trunk_groups').
          with(body:
            {
              "data": {
                "type": 'trunk_groups',
                "attributes": {
                  "name": 'Main group',
                  "capacity_limit": 100
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunk_groups/post/sample_1/201'),
            headers: json_api_headers
          )
        trunk_group = client.trunk_groups.create(name: 'Main group', capacity_limit: 100)
        expect(trunk_group).to be_persisted
      end

      it 'creates a TrunkGroup and assign Trunks' do
        stub_didww_request(:post, '/trunk_groups').
          with(body:
            {
              "data": {
                "type": 'trunk_groups',
                "relationships": {
                  "trunks": {
                    "data": [
                      {
                        "type": 'trunks',
                        "id": 'b7a9d1ce-6a89-4071-bc0d-486ee223787d'
                      },
                      {
                        "type": 'trunks',
                        "id": '7ca415f8-8342-427a-bbfc-171b995f75d6'
                      },
                      {
                        "type": 'trunks',
                        "id": '46aa9cac-a8dd-4a06-82db-cb0731e53ba0'
                      }
                    ]
                  }
                },
                "attributes": {
                  "name": 'Main group',
                  "capacity_limit": 100
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunk_groups/post/sample_2/201'),
            headers: json_api_headers
          )
        trunk_group = client.trunk_groups.new(name: 'Main group', capacity_limit: 100)
        trunk_group.relationships[:trunks] = [
          DIDWW::Resource::Trunk.load(id:'b7a9d1ce-6a89-4071-bc0d-486ee223787d'),
          DIDWW::Resource::Trunk.load(id:'7ca415f8-8342-427a-bbfc-171b995f75d6'),
          DIDWW::Resource::Trunk.load(id:'46aa9cac-a8dd-4a06-82db-cb0731e53ba0')
        ]
        trunk_group.save
        expect(trunk_group).to be_persisted
      end

      xit 'creates a TrunkGroup, assign Trunks and include them in response'
    end

    describe 'with incorerct attributes' do
      it 'returns a TrunkGroup with errors' do
        stub_didww_request(:post, '/trunk_groups').
          with(body:
            {
              "data": {
                "type": 'trunk_groups',
                "attributes": {
                  "name": 'Main group',
                  "capacity_limit": 100
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('trunk_groups/post/sample_1/422'),
            headers: json_api_headers
          )
        trunk_group = client.trunk_groups.create(name: 'Main group', capacity_limit: 100)
        expect(trunk_group.errors).to have_at_least(1).item
      end
    end
  end

  describe 'PATCH /trunk_groups/{id}' do
    describe 'with correct attributes' do
      it 'updates a TrunkGroup' do
        id = '43deb3aa-674a-465e-ac16-fb3084325ec7'
        stub_didww_request(:patch, "/trunk_groups/#{id}").
          with(body:
            {
              "data": {
                "id": '43deb3aa-674a-465e-ac16-fb3084325ec7',
                "type": 'trunk_groups',
                "attributes": {
                  "name": 'Renamed group',
                  "capacity_limit": 1
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunk_groups/id/patch/sample_1/200'),
            headers: json_api_headers
          )
        trunk_group = DIDWW::Resource::TrunkGroup.load(id: id)
        trunk_group.update(name: 'Renamed group', capacity_limit: 1)
        expect(trunk_group.errors).to be_empty
        expect(trunk_group.name).to eq('Renamed group')
        expect(trunk_group.capacity_limit).to eq(1)
      end

      it 'updates a TrunkGroup with removing Trunks' do
        id = 'e74fcf6a-bb8d-4ee0-9980-bdc24a728b9a'
        stub_didww_request(:patch, "/trunk_groups/#{id}").
          with(body:
            {
              "data": {
                "id": 'e74fcf6a-bb8d-4ee0-9980-bdc24a728b9a',
                "type": 'trunk_groups',
                "relationships": {
                  "trunks": {
                    "data": [ ]
                  }
                },
                "attributes": {}
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunk_groups/id/patch/sample_2/200'),
            headers: json_api_headers
          )
        trunk_group = DIDWW::Resource::TrunkGroup.load(id: id)
        trunk_group.relationships[:trunks] = []
        expect(trunk_group.save)
      end
    end

    describe 'with incorerct attributes' do
      it 'returns a TrunkGroup with errors' do
        id = '43deb3aa-674a-465e-ac16-fb3084325ec7'
        stub_didww_request(:patch, "/trunk_groups/#{id}").
          with(body:
            {
              "data": {
                "id": '43deb3aa-674a-465e-ac16-fb3084325ec7',
                "type": 'trunk_groups',
                "attributes": {
                  "name": 'Renamed group',
                  "capacity_limit": 1
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('trunk_groups/id/patch/sample_1/422'),
            headers: json_api_headers
          )
        trunk_group = DIDWW::Resource::TrunkGroup.load(id: id)
        trunk_group.update(name: 'Renamed group', capacity_limit: 1)
        expect(trunk_group.errors).to have_at_least(1).item
      end
    end
  end

  describe 'DELETE /trunk_groups/{id}' do
    let (:id) { '1156df17-bcea-4c9a-9c1d-29320e288c03' }
    it 'deletes a TrunkGroup' do
      stub_didww_request(:delete, "/trunk_groups/#{id}").
        to_return(
          status: 202,
          body: api_fixture('trunk_groups/id/delete/sample_1/202'),
          headers: json_api_headers
        )
      trunk_group = DIDWW::Resource::TrunkGroup.load(id: id)
      expect(trunk_group.destroy)
      expect(WebMock).to have_requested(:delete, api_uri("/trunk_groups/#{id}"))
    end

    context 'when TrunkGroup does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:delete, "/trunk_groups/#{id}").
        to_return(
          status: 404,
          body: api_fixture('trunk_groups/id/delete/sample_1/404'),
          headers: json_api_headers
        )
        trunk_group = DIDWW::Resource::TrunkGroup.load(id: id)
        expect { trunk_group.destroy }.to raise_error(JsonApiClient::Errors::NotFound)
        expect(WebMock).to have_requested(:delete, api_uri("/trunk_groups/#{id}"))
      end
    end
  end
end
