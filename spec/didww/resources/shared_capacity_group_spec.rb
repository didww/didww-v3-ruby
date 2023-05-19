# frozen_string_literal: true
RSpec.describe DIDWW::Resource::SharedCapacityGroup do
  let (:client) { DIDWW::Client }

  describe 'GET /shared_capacity_groups/{id}' do
    let (:id) { 'dd2e8844-6a79-4673-ba1c-c8a4913884cc' }

    context 'when SharedCapacityGroup exists' do
      let (:shared_capacity_group) do
        stub_didww_request(:get, "/shared_capacity_groups/#{id}").to_return(
          status: 200,
          body: api_fixture('shared_capacity_groups/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.shared_capacity_groups.find(id).first
      end

      it 'returns a single SharedCapacityGroup' do
        expect(shared_capacity_group).to be_kind_of(DIDWW::Resource::SharedCapacityGroup)
        expect(shared_capacity_group.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"name", type: String' do
          expect(shared_capacity_group.name).to be_kind_of(String)
        end
        it '"shared_channels_count", type: Integer' do
          expect(shared_capacity_group.shared_channels_count).to be_kind_of(Integer)
        end
        it '"metered_channels_count", type: Integer' do
          expect(shared_capacity_group.metered_channels_count).to be_kind_of(Integer)
        end
        it '"created_at", type: Time' do
          expect(shared_capacity_group.created_at).to be_kind_of(Time)
        end
      end

      it 'lazily fetches CapacityPool' do
        request = stub_request(:get, shared_capacity_group.relationships.capacity_pool[:links][:related]).to_return(
            status: 200,
            body: api_fixture('capacity_pools/id/get/sample_1/200'),
            headers: json_api_headers
          )
        expect(shared_capacity_group.capacity_pool).to be_kind_of(DIDWW::Resource::CapacityPool)
        expect(request).to have_been_made.once
      end

      it 'lazily fetches Dids' do
        request = stub_request(:get, shared_capacity_group.relationships.dids[:links][:related]).to_return(
            status: 200,
            body: api_fixture('dids/get/sample_1/200'),
            headers: json_api_headers
          )
        expect(shared_capacity_group.dids).to all be_an_instance_of(DIDWW::Resource::Did)
        expect(request).to have_been_made.once
      end
    end

    context 'when SharedCapacityGroup does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/shared_capacity_groups/#{id}").to_return(
          status: 404,
          body: api_fixture('shared_capacity_groups/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.shared_capacity_groups.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes CapacityPool and Dids' do
      stub_didww_request(:get, "/shared_capacity_groups/#{id}?include=capacity_pool,dids").to_return(
        status: 200,
        body: api_fixture('shared_capacity_groups/id/get/sample_2/200'),
        headers: json_api_headers
      )
      shared_capacity_group = client.shared_capacity_groups.includes(:capacity_pool, :dids).find(id).first
      expect(shared_capacity_group.capacity_pool).to be_kind_of(DIDWW::Resource::CapacityPool)
      expect(shared_capacity_group.dids).to all be_an_instance_of(DIDWW::Resource::Did)
    end
  end

  describe 'GET /shared_capacity_groups' do
    it 'returns a collection of SharedCapacityGroups' do
      stub_didww_request(:get, '/shared_capacity_groups').to_return(
        status: 200,
        body: api_fixture('shared_capacity_groups/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.shared_capacity_groups.all).to all be_an_instance_of(DIDWW::Resource::SharedCapacityGroup)
    end
    it 'optionally includes Capacity Pool, Dids' do
      stub_didww_request(:get, '/shared_capacity_groups?include=capacity_pool,dids').to_return(
        status: 200,
        body: api_fixture('shared_capacity_groups/get/sample_2/200'),
        headers: json_api_headers
      )
      shared_capacity_groups = client.shared_capacity_groups.includes(:capacity_pool, :dids).all
      expect(shared_capacity_groups.first.capacity_pool).to be_kind_of(DIDWW::Resource::CapacityPool)
      expect(shared_capacity_groups.first.dids).to all be_an_instance_of(DIDWW::Resource::Did)
    end
  end

  describe 'POST /shared_capacity_groups' do
    let(:stub_post_shared_capacity_group_with_capacity_pool) do
      stub_didww_request(:post, '/shared_capacity_groups').
        with(body:
          {
            "data": {
              "type": 'shared_capacity_groups',
              "relationships": {
                "capacity_pool": {
                  "data": {
                    "type": 'capacity_pools',
                    "id": '71185c2a-fcc7-468b-87e3-85260fbc3b86'
                  }
                }
              },
              "attributes": {
                "name": 'Sample Capacity Group',
                "shared_channels_count": 3,
                "metered_channels_count": 5
              }
            }
          }.to_json
        )
    end

    let(:stub_post_shared_capacity_group_with_capacity_pool_and_dids) do
      stub_didww_request(:post, '/shared_capacity_groups').
        with(body:
          {
            "data": {
              "type": 'shared_capacity_groups',
              "relationships": {
                "capacity_pool": {
                  "data": {
                    "type": 'capacity_pools',
                    "id": '71185c2a-fcc7-468b-87e3-85260fbc3b86'
                  }
                },
                "dids": {
                  "data": [
                    {
                      "type": 'dids',
                      "id": 'b7a9d1ce-6a89-4071-bc0d-486ee223787d'
                    },
                    {
                      "type": 'dids',
                      "id": '7ca415f8-8342-427a-bbfc-171b995f75d6'
                    },
                    {
                      "type": 'dids',
                      "id": '46aa9cac-a8dd-4a06-82db-cb0731e53ba0'
                    }
                  ]
                }
              },
              "attributes": {
                "name": 'Sample Capacity Group',
                "shared_channels_count": 3,
                "metered_channels_count": 5
              }
            }
          }.to_json
        )
    end

    describe 'with correct attributes' do
      it 'creates a SharedCapacityGroup' do
        stub_post_shared_capacity_group_with_capacity_pool.to_return(
          status: 201,
          body: api_fixture('shared_capacity_groups/post/sample_1/201'),
          headers: json_api_headers
        )

        shared_capacity_group = client.shared_capacity_groups.new(name: 'Sample Capacity Group', shared_channels_count: 3, metered_channels_count: 5)
        shared_capacity_group.relationships[:capacity_pool] = DIDWW::Resource::CapacityPool.load(id: '71185c2a-fcc7-468b-87e3-85260fbc3b86')
        shared_capacity_group.save
        expect(shared_capacity_group).to be_persisted
      end

      it 'creates a SharedCapacityGroup and assign DIDs' do
        stub_post_shared_capacity_group_with_capacity_pool_and_dids.to_return(
          status: 201,
          body: api_fixture('shared_capacity_groups/post/sample_2/201'),
          headers: json_api_headers
        )

        shared_capacity_group = client.shared_capacity_groups.new(name: 'Sample Capacity Group', shared_channels_count: 3, metered_channels_count: 5)
        shared_capacity_group.relationships[:capacity_pool] = DIDWW::Resource::CapacityPool.load(id: '71185c2a-fcc7-468b-87e3-85260fbc3b86')
        shared_capacity_group.relationships[:dids] = [
          DIDWW::Resource::Did.load(id:'b7a9d1ce-6a89-4071-bc0d-486ee223787d'),
          DIDWW::Resource::Did.load(id:'7ca415f8-8342-427a-bbfc-171b995f75d6'),
          DIDWW::Resource::Did.load(id:'46aa9cac-a8dd-4a06-82db-cb0731e53ba0')
        ]
        shared_capacity_group.save
        expect(shared_capacity_group).to be_persisted
      end

      xit 'creates a SharedCapacityGroup, assign Dids and include them in response'
    end

    describe 'with incorrect attributes' do
      it 'returns a SharedCapacityGroup with errors' do
        stub_post_shared_capacity_group_with_capacity_pool.to_return(
          status: 422,
          body: api_fixture('shared_capacity_groups/post/sample_1/422'),
          headers: json_api_headers
        )

        shared_capacity_group = client.shared_capacity_groups.new(name: 'Sample Capacity Group', shared_channels_count: 3, metered_channels_count: 5)
        shared_capacity_group.relationships[:capacity_pool] = DIDWW::Resource::CapacityPool.load(id: '71185c2a-fcc7-468b-87e3-85260fbc3b86')
        shared_capacity_group.save
        expect(shared_capacity_group.errors.count).to eq 1
        expect(shared_capacity_group.errors[:name]).to contain_exactly('has already been taken')
      end
    end

    context 'when some of DID cannot be applied to shared capacity group' do
      it 'returns a validation error' do
        stub_post_shared_capacity_group_with_capacity_pool_and_dids.to_return(
          status: 422,
          body: api_fixture('shared_capacity_groups/post/sample_2/422'),
          headers: json_api_headers
        )
        shared_capacity_group = client.shared_capacity_groups.new(name: 'Sample Capacity Group', shared_channels_count: 3, metered_channels_count: 5)
        shared_capacity_group.relationships[:capacity_pool] = DIDWW::Resource::CapacityPool.load(id: '71185c2a-fcc7-468b-87e3-85260fbc3b86')
        shared_capacity_group.relationships[:dids] = [
          DIDWW::Resource::Did.load(id:'b7a9d1ce-6a89-4071-bc0d-486ee223787d'),
          DIDWW::Resource::Did.load(id:'7ca415f8-8342-427a-bbfc-171b995f75d6'),
          DIDWW::Resource::Did.load(id:'46aa9cac-a8dd-4a06-82db-cb0731e53ba0')
        ]
        shared_capacity_group.save
        expect(shared_capacity_group.errors.count).to eq 1
        expect(shared_capacity_group.errors['0']).to contain_exactly('cannot be applied to shared capacity group')
      end
    end
  end

  describe 'PATCH /shared_capacity_groups/{id}' do
    let(:id) { 'dd2e8844-6a79-4673-ba1c-c8a4913884cc' }
    describe 'with correct attributes' do
      it 'updates a SharedCapacityGroup' do
        stub_didww_request(:patch, "/shared_capacity_groups/#{id}").
          with(body:
            {
              "data": {
                "id": 'dd2e8844-6a79-4673-ba1c-c8a4913884cc',
                "type": 'shared_capacity_groups',
                "attributes": {
                  "name": 'Renamed group',
                  "shared_channels_count": 1,
                  "dedicated_channels_count": 2
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('shared_capacity_groups/id/patch/sample_1/200'),
            headers: json_api_headers
          )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        shared_capacity_group.update(name: 'Renamed group', shared_channels_count: 1, dedicated_channels_count: 2)
        expect(shared_capacity_group.errors).to be_empty
        expect(shared_capacity_group.name).to eq('Renamed group')
      end

      it 'updates a SharedCapacityGroup with removing DIDs' do
        stub_didww_request(:patch, "/shared_capacity_groups/#{id}").
          with(body:
            {
              "data": {
                "id": 'dd2e8844-6a79-4673-ba1c-c8a4913884cc',
                "type": 'shared_capacity_groups',
                "relationships": {
                  "dids": {
                    "data": [ ]
                  }
                },
                "attributes": {}
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('shared_capacity_groups/id/patch/sample_2/200'),
            headers: json_api_headers
          )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        shared_capacity_group.relationships[:dids] = []
        expect(shared_capacity_group.save)
      end

      it 'updates a SharedCapacityGroup with replacing DIDs list' do
        stub_didww_request(:patch, "/shared_capacity_groups/#{id}").
          with(body:
            {
              "data": {
                "id": 'dd2e8844-6a79-4673-ba1c-c8a4913884cc',
                "type": 'shared_capacity_groups',
                "relationships": {
                  "dids": {
                    "data": [
                      {
                        "type": 'dids',
                        "id": 'b7a9d1ce-6a89-4071-bc0d-486ee223787d'
                      },
                      {
                        "type": 'dids',
                        "id": '7ca415f8-8342-427a-bbfc-171b995f75d6'
                      },
                      {
                        "type": 'dids',
                        "id": '46aa9cac-a8dd-4a06-82db-cb0731e53ba0'
                      }
                    ]
                  }
                },
                "attributes": {}
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('shared_capacity_groups/id/patch/sample_3/200'),
            headers: json_api_headers
          )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        shared_capacity_group.relationships[:dids] = [
          DIDWW::Resource::Did.load(id:'b7a9d1ce-6a89-4071-bc0d-486ee223787d'),
          DIDWW::Resource::Did.load(id:'7ca415f8-8342-427a-bbfc-171b995f75d6'),
          DIDWW::Resource::Did.load(id:'46aa9cac-a8dd-4a06-82db-cb0731e53ba0')
        ]
        expect(shared_capacity_group.save)
      end
    end

    describe 'with incorrect attributes' do
      it 'returns a SharedCapacityGroup with errors' do
        stub_didww_request(:patch, "/shared_capacity_groups/#{id}").
          with(body:
            {
              "data": {
                "id": 'dd2e8844-6a79-4673-ba1c-c8a4913884cc',
                "type": 'shared_capacity_groups',
                "attributes": {
                  "name": 'Renamed group'
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('shared_capacity_groups/id/patch/sample_1/422'),
            headers: json_api_headers
          )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        shared_capacity_group.update(name: 'Renamed group')
        expect(shared_capacity_group.errors.count).to eq 1
        expect(shared_capacity_group.errors[:name]).to contain_exactly('has already been taken')
      end
    end

    context 'when some of DID cannot be applied to shared capacity group' do
      it 'returns a validation error' do
        stub_didww_request(:patch, "/shared_capacity_groups/#{id}").
          with(body:
            {
              "data": {
                "id": 'dd2e8844-6a79-4673-ba1c-c8a4913884cc',
                "type": 'shared_capacity_groups',
                "relationships": {
                  "dids": {
                    "data": [
                      {
                        "type": 'dids',
                        "id": 'b7a9d1ce-6a89-4071-bc0d-486ee223787d'
                      }
                    ]
                  }
                },
                "attributes": {}
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('shared_capacity_groups/id/patch/sample_3/422'),
            headers: json_api_headers
          )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        shared_capacity_group.relationships[:dids] = [
          DIDWW::Resource::Did.load(id:'b7a9d1ce-6a89-4071-bc0d-486ee223787d')
        ]
        shared_capacity_group.save
        expect(shared_capacity_group.errors.count).to eq 1
        expect(shared_capacity_group.errors['0']).to contain_exactly('cannot be applied to shared capacity group')
      end
    end
  end

  describe 'DELETE /shared_capacity_groups/{id}' do
    let (:id) { 'dd2e8844-6a79-4673-ba1c-c8a4913884cc' }
    it 'deletes a SharedCapacityGroup' do
      stub_didww_request(:delete, "/shared_capacity_groups/#{id}").
        to_return(
          status: 202,
          body: api_fixture('shared_capacity_groups/id/delete/sample_1/202'),
          headers: json_api_headers
        )
      shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
      expect(shared_capacity_group.destroy)
      expect(WebMock).to have_requested(:delete, api_uri("/shared_capacity_groups/#{id}"))
    end

    context 'when SharedCapacityGroup does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:delete, "/shared_capacity_groups/#{id}").
        to_return(
          status: 404,
          body: api_fixture('shared_capacity_groups/id/delete/sample_1/404'),
          headers: json_api_headers
        )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        expect { shared_capacity_group.destroy }.to raise_error(JsonApiClient::Errors::NotFound)
        expect(WebMock).to have_requested(:delete, api_uri("/shared_capacity_groups/#{id}"))
      end
    end

    context 'when SharedCapacityGroup has assigned DIDs' do
      it 'returns a SharedCapacityGroup with errors' do
        stub_didww_request(:delete, "/shared_capacity_groups/#{id}").
        to_return(
          status: 422,
          body: api_fixture('shared_capacity_groups/id/delete/sample_1/422'),
          headers: json_api_headers
        )
        shared_capacity_group = DIDWW::Resource::SharedCapacityGroup.load(id: id)
        expect(shared_capacity_group.destroy).to eq(false)
        expect(shared_capacity_group.errors.count).to eq 1
        expect(shared_capacity_group.errors[:base]).to contain_exactly('The capacity group cannot be removed while active numbers are assigned to it')
        expect(WebMock).to have_requested(:delete, api_uri("/shared_capacity_groups/#{id}"))
      end
    end
  end
end
