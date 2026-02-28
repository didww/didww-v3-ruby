# frozen_string_literal: true
RSpec.describe DIDWW::Resource::CapacityPool do
  let (:client) { DIDWW::Client }

  describe 'GET /capacity_pools/:id' do
    let (:id) { 'b8db1d7c-f415-4530-a340-c774bcc1c55f' }

    context 'when CapacityPool exists' do
      let (:capacity_pool) do
        stub_didww_request(:get, "/capacity_pools/#{id}").to_return(
          status: 200,
          body: api_fixture('capacity_pools/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.capacity_pools.find(id).first
      end

      it 'returns a single CapacityPool' do
        expect(capacity_pool).to be_an_instance_of(described_class)
        expect(capacity_pool.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"name", type: String' do
          expect(capacity_pool.name).to be_kind_of(String)
        end
        it '"renew_date", type: String' do
          expect(capacity_pool.renew_date).to be_kind_of(String)
        end
        it '"total_channels_count", type: Integer' do
          expect(capacity_pool.total_channels_count).to be_kind_of(Integer)
        end
        it '"assigned_channels_count", type: Integer' do
          expect(capacity_pool.assigned_channels_count).to be_kind_of(Integer)
        end
        it '"minimum_limit", type: Integer' do
          expect(capacity_pool.minimum_limit).to be_kind_of(Integer)
        end
        it '"minimum_qty_per_order", type: Integer' do
          expect(capacity_pool.minimum_qty_per_order).to be_kind_of(Integer)
        end
        it '"setup_price", type: BigDecimal' do
          expect(capacity_pool.setup_price).to be_kind_of(BigDecimal)
        end
        it '"monthly_price", type: BigDecimal' do
          expect(capacity_pool.monthly_price).to be_kind_of(BigDecimal)
        end
        it '"metered_rate", type: BigDecimal' do
          expect(capacity_pool.metered_rate).to be_kind_of(BigDecimal)
        end
      end

      it 'lazily fetches Countries' do
        request = stub_request(:get, capacity_pool.relationships.countries[:links][:related]).to_return(
            status: 200,
            body: api_fixture('countries/get/without_includes/200'),
            headers: json_api_headers
          )
        expect(capacity_pool.countries).to all be_an_instance_of(DIDWW::Resource::Country)
        expect(request).to have_been_made.once
      end

      it 'lazily fetches SharedCapacityGroups' do
        request = stub_request(:get, capacity_pool.relationships.shared_capacity_groups[:links][:related]).to_return(
            status: 200,
            body: api_fixture('shared_capacity_groups/get/without_includes/200'),
            headers: json_api_headers
          )
        expect(capacity_pool.shared_capacity_groups).to all be_an_instance_of(DIDWW::Resource::SharedCapacityGroup)
        expect(request).to have_been_made.once
      end
    end

    context 'when CapacityPool does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/capacity_pools/#{id}").to_return(
          status: 404,
          body: api_fixture('capacity_pools/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.capacity_pools.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes Countries, Shared capacity groups and Quantity Based Pricings' do
      stub_didww_request(:get, "/capacity_pools/#{id}?include=countries,shared_capacity_groups,qty_based_pricings").to_return(
        status: 200,
        body: api_fixture('capacity_pools/id/get/with_included_relationships/200'),
        headers: json_api_headers
      )
      capacity_pool = client.capacity_pools.includes(:countries, :shared_capacity_groups, :qty_based_pricings).find(id).first
      expect(capacity_pool.countries).to all be_an_instance_of(DIDWW::Resource::Country)
      expect(capacity_pool.shared_capacity_groups).to all be_an_instance_of(DIDWW::Resource::SharedCapacityGroup)
      expect(capacity_pool.qty_based_pricings).to all be_an_instance_of(DIDWW::Resource::QtyBasedPricing)
    end
  end

  describe 'GET /capacity_pools' do
    it 'returns a collection of CapacityPools' do
      stub_didww_request(:get, '/capacity_pools').to_return(
        status: 200,
        body: api_fixture('capacity_pools/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.capacity_pools.all).to all be_an_instance_of(DIDWW::Resource::CapacityPool)
    end
    it 'optionally includes Countries, Shared capacity groups and Quantity Based Pricings' do
      stub_didww_request(:get, '/capacity_pools?include=countries,shared_capacity_groups,qty_based_pricings').to_return(
        status: 200,
        body: api_fixture('capacity_pools/get/with_included_relationships/200'),
        headers: json_api_headers
      )
      capacity_pools = client.capacity_pools.includes(:countries, :shared_capacity_groups, :qty_based_pricings).all
      expect(capacity_pools.first.countries).to all be_an_instance_of(DIDWW::Resource::Country)
      expect(capacity_pools.first.shared_capacity_groups).to all be_an_instance_of(DIDWW::Resource::SharedCapacityGroup)
      expect(capacity_pools.first.qty_based_pricings).to all be_an_instance_of(DIDWW::Resource::QtyBasedPricing)
    end
  end

  describe 'PATCH /capacity_pools/{id}' do
    describe 'with correct attributes' do
      it 'updates a CapacityPool' do
        id = 'b8db1d7c-f415-4530-a340-c774bcc1c55f'
        stub_didww_request(:patch, "/capacity_pools/#{id}").
          with(body:
            {
              "data": {
                "id": 'b8db1d7c-f415-4530-a340-c774bcc1c55f',
                "type": 'capacity_pools',
                "attributes": {
                  "total_channels_count": 7
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('capacity_pools/id/patch/update_attributes/200'),
            headers: json_api_headers
          )
        capacity_pool = DIDWW::Resource::CapacityPool.load(id: id).tap do |cp|
          cp.total_channels_count = 7
        end
        expect(capacity_pool.save)
        expect(capacity_pool.errors).to be_empty
        expect(capacity_pool.total_channels_count).to eq(7)
      end
    end

    describe 'with incorerct attributes' do
      it 'returns a CapacityPool with errors' do
        id = 'b8db1d7c-f415-4530-a340-c774bcc1c55f'
        stub_didww_request(:patch, "/capacity_pools/#{id}").
          with(body:
            {
              "data": {
                "id": 'b8db1d7c-f415-4530-a340-c774bcc1c55f',
                "type": 'capacity_pools',
                "attributes": {
                  "total_channels_count": 1
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('capacity_pools/id/patch/update_attributes/422'),
            headers: json_api_headers
          )
        capacity_pool = DIDWW::Resource::CapacityPool.load(id: id).tap do |cp|
          cp.total_channels_count = 1
        end
        capacity_pool.save
        expect(capacity_pool.errors.count).to eq 1
        expect(capacity_pool.errors[:total_channels_count]).to contain_exactly('should be at least 2')
      end
    end

  end

end
