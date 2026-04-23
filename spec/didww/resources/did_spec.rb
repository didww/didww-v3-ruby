# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Did do
  let (:client) { DIDWW::Client }

  describe 'emergency_calling_service relationship (2026-04-16)' do
    it 'has emergency_calling_service has_one relationship' do
      did = described_class.new
      expect(did).to respond_to(:emergency_calling_service)
    end
  end

  describe 'emergency_verification relationship (2026-04-16)' do
    it 'has emergency_verification has_one relationship' do
      did = described_class.new
      expect(did).to respond_to(:emergency_verification)
    end
  end

  describe 'identity relationship (2026-04-16)' do
    it 'has identity has_one relationship' do
      did = described_class.new
      expect(did).to respond_to(:identity)
    end
  end

  describe 'GET /dids/:id' do
    let (:id) { '44957076-778a-4802-b60c-d22db0cda284' }

    context 'when Did exists' do
      let (:did) do
        stub_didww_request(:get, "/dids/#{id}").to_return(
          status: 200,
          body: api_fixture('dids/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.dids.find(id).first
      end

      it 'returns a single Did' do
        expect(did).to be_kind_of(DIDWW::Resource::Did)
        expect(did.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"blocked", type: Boolean' do
          expect(did.blocked).to be_in([true, false])
        end
        it '"awaiting_registration", type: Boolean' do
          expect(did.awaiting_registration).to be_in([true, false])
        end
        it '"terminated", type: Boolean' do
          expect(did.terminated).to be_in([true, false])
        end
        it '"billing_cycles_count", type: Integer' do
          expect(did.billing_cycles_count).to be_kind_of(Integer)
        end
        it '"description", type: String' do
          expect(did.description).to be_kind_of(String)
        end
        it '"number", type: String' do
          expect(did.number).to be_kind_of(String)
        end
        it '"capacity_limit", type: Integer' do
          expect(did.capacity_limit).to be_kind_of(Integer)
        end
        it '"channels_included_count", type: Integer' do
          expect(did.channels_included_count).to be_kind_of(Integer).or be_nil
        end
        it '"expires_at", type: Time' do
          expect(did.expires_at).to be_kind_of(Time)
        end
        it '"created_at", type: Time' do
          expect(did.created_at).to be_kind_of(Time)
        end
        it '"emergency_enabled", type: Boolean' do
          expect(did.emergency_enabled).to be_in([true, false])
        end
      end

      it 'lazily fetches Trunk' do
        request = stub_request(:get, did.relationships.voice_in_trunk[:links][:related]).to_return(
            status: 200,
            body: api_fixture('voice_in_trunks/id/get/sip_trunk/200'),
            headers: json_api_headers
          )
        expect(did.voice_in_trunk).to be_kind_of(DIDWW::Resource::VoiceInTrunk)
        expect(request).to have_been_made.once
      end

      it 'lazily fetches TrunkGroup' do
        request = stub_request(:get, did.relationships.voice_in_trunk_group[:links][:related]).to_return(
            status: 200,
            body: api_fixture('voice_in_trunk_groups/id/get/without_includes/200'),
            headers: json_api_headers
          )
        expect(did.voice_in_trunk_group).to be_kind_of(DIDWW::Resource::VoiceInTrunkGroup)
        expect(request).to have_been_made.once
      end

    end

    context 'when Did does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/dids/#{id}").to_return(
          status: 404,
          body: api_fixture('dids/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.dids.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes DidGroup' do
      stub_didww_request(:get, "/dids/#{id}?include=did_group").to_return(
        status: 200,
        body: api_fixture('dids/id/get/with_included_did_group/200'),
        headers: json_api_headers
      )
      did = client.dids.includes(:did_group).find(id).first
      expect(did.did_group).to be_kind_of(DIDWW::Resource::DidGroup)
    end

    it 'optionally includes AddressVerification and DidGroup' do
      stub_didww_request(:get, "/dids/#{id}?include=address_verification,did_group").to_return(
        status: 200,
        body: api_fixture('dids/id/get/with_included_address_verification_and_did_group/200'),
        headers: json_api_headers
      )
      did = client.dids.includes(:address_verification, :did_group).find(id).first
      expect(did.address_verification).to be_kind_of(DIDWW::Resource::AddressVerification)
      expect(did.did_group).to be_kind_of(DIDWW::Resource::DidGroup)
    end
  end

  describe 'GET /dids' do
    it 'returns a collection of Dids' do
      stub_didww_request(:get, '/dids').to_return(
        status: 200,
        body: api_fixture('dids/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.dids.all).to all be_an_instance_of(DIDWW::Resource::Did)
    end
    it 'optionally includes DidGroup' do
      stub_didww_request(:get, '/dids?include=did_group').to_return(
        status: 200,
        body: api_fixture('dids/get/with_included_did_group/200'),
        headers: json_api_headers
      )
      expect(client.dids.includes(:did_group).all.first.did_group).to be_kind_of(DIDWW::Resource::DidGroup)
    end
  end

  describe 'PATCH /dids/{id}' do
    let(:voice_in_trunk_id) { 'c80d096a-c8cf-4449-aa6d-8bac39130fe0' }
    let(:voice_in_trunk_group_id) { '1dc6e448-d9d8-4da8-a34b-21459b03112f' }
    let(:capacity_pool_id) { '1e9e4362-bc5c-47f3-a2bb-c17afa66f3fa' }
    let(:shared_capacity_group_id) { '31e08e8f-f3c6-49dd-acb2-d9335828879e' }

    describe 'with correct attributes' do
      it 'updates a Did' do
        id = '46e129f1-deaa-44db-8915-2646de4d4c70'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            attributes: {
              terminated: false,
              billing_cycles_count: 1,
              description: 'string',
              capacity_limit: 1
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('dids/id/patch/update_attributes/200'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id).tap do |d|
          d.terminated = false
          d.billing_cycles_count = 1
          d.description = 'string'
          d.capacity_limit = 1
        end
        expect(did.save)
        expect(did.errors).to be_empty
        expect(did.terminated).to eq(false)
        expect(did.billing_cycles_count).to eq(1)
        expect(did.description).to eq('string')
        expect(did.capacity_limit).to eq(1)
      end

      it 'assigns a Trunk to Did' do
        id = '3505b18a-3019-47bc-95d1-0f9ec7766fd5'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              voice_in_trunk: {
                data: { type: 'voice_in_trunks', id: voice_in_trunk_id }
              },
              voice_in_trunk_group: { data: nil }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('dids/id/patch/assign_voice_in_trunk/200'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:voice_in_trunk] = DIDWW::Resource::VoiceInTrunk.load(id: voice_in_trunk_id)
        expect(did.save)
        expect(did.errors).to be_empty
      end

      it 'assigns a TrunkGroup to Did' do
        id = '3e3f57ec-0541-473a-af63-103216d19db3'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              voice_in_trunk_group: {
                data: { type: 'voice_in_trunk_groups', id: voice_in_trunk_group_id }
              },
              voice_in_trunk: { data: nil }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('dids/id/patch/assign_voice_in_trunk_group/200'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:voice_in_trunk_group] = DIDWW::Resource::VoiceInTrunkGroup.load(id: voice_in_trunk_group_id)

        expect(did.save)
        expect(did.errors).to be_empty
      end

      it 'assigns a CapacityPool to Did' do
        id = '3e3f57ec-0541-473a-af63-103216d19db3'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              capacity_pool: {
                data: { type: 'capacity_pools', id: capacity_pool_id }
              }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('dids/id/patch/assign_capacity_pool/200'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:capacity_pool] = DIDWW::Resource::CapacityPool.load(id: capacity_pool_id)

        expect(did.save)
        expect(did.errors).to be_empty
      end

      it 'unassigns EmergencyCallingService from Did (emergency_calling_service: { data: null })' do
        id = '44957076-778a-4802-b60c-d22db0cda284'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              emergency_calling_service: { data: nil }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('dids/id/patch/unassign_emergency_calling_service/200'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:emergency_calling_service] = nil
        expect(did.save)
        expect(did.errors).to be_empty
      end

      it 'assigns a SharedCapacityGroup to Did' do
        id = '3e3f57ec-0541-473a-af63-103216d19db3'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              shared_capacity_group: {
                data: { type: 'shared_capacity_groups', id: shared_capacity_group_id }
              }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('dids/id/patch/assign_shared_capacity_group/200'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:shared_capacity_group] = DIDWW::Resource::SharedCapacityGroup.load(id: shared_capacity_group_id)

        expect(did.save)
        expect(did.errors).to be_empty
      end
    end

    describe 'with incorrect attributes' do
      it 'returns a Did with errors' do
        id = '46e129f1-deaa-44db-8915-2646de4d4c70'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            attributes: {
              terminated: false,
              billing_cycles_count: 1,
              description: 'string',
              capacity_limit: 1
            }
          )).
          to_return(
            status: 422,
            body: api_fixture('dids/id/patch/update_attributes/422'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id).tap do |d|
          d.terminated = false
          d.billing_cycles_count = 1
          d.description = 'string'
          d.capacity_limit = 1
        end
        did.save
        expect(did.errors.count).to eq 1
        expect(did.errors[:capacity_limit]).to contain_exactly 'must be less than or equal to 32767'
      end
    end

    describe 'with incompatible CapacityPool' do
      it 'returns a Did with errors' do
        id = '3e3f57ec-0541-473a-af63-103216d19db3'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              capacity_pool: {
                data: { type: 'capacity_pools', id: capacity_pool_id }
              }
            }
          )).
          to_return(
            status: 422,
            body: api_fixture('dids/id/patch/assign_capacity_pool/422'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:capacity_pool] = DIDWW::Resource::CapacityPool.load(id: capacity_pool_id)

        did.save
        expect(did.errors.count).to eq 1
        expect(did.errors[:capacity_pool_id]).to contain_exactly('is not allowed for DID country')
      end
    end

    describe 'with incompatible SharedCapacityGroup' do
      it 'returns a Did with errors' do
        id = '3e3f57ec-0541-473a-af63-103216d19db3'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              shared_capacity_group: {
                data: { type: 'shared_capacity_groups', id: shared_capacity_group_id }
              }
            }
          )).
          to_return(
            status: 422,
            body: api_fixture('dids/id/patch/assign_shared_capacity_group/422'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:shared_capacity_group] = DIDWW::Resource::SharedCapacityGroup.load(id: shared_capacity_group_id)

        did.save
        expect(did.errors.count).to eq 1
        expect(did.errors[:shared_capacity_group_id]).to contain_exactly('is not allowed for DID country')
      end
    end

    describe 'with invalid VoiceInTrunk' do
      it 'returns a Did with errors' do
        id = '3505b18a-3019-47bc-95d1-0f9ec7766fd5'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              voice_in_trunk: {
                data: { type: 'voice_in_trunks', id: voice_in_trunk_id }
              },
              voice_in_trunk_group: { data: nil }
            }
          )).
          to_return(
            status: 422,
            body: api_fixture('dids/id/patch/assign_voice_in_trunk/422'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:voice_in_trunk] = DIDWW::Resource::VoiceInTrunk.load(id: voice_in_trunk_id)

        did.save
        expect(did.errors.count).to eq 1
        expect(did.errors[:voice_in_trunk_id]).to contain_exactly('should exist')
      end
    end

    describe 'with invalid VoiceInTrunkGroup' do
      it 'returns a Did with errors' do
        id = '3e3f57ec-0541-473a-af63-103216d19db3'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            relationships: {
              voice_in_trunk_group: {
                data: { type: 'voice_in_trunk_groups', id: voice_in_trunk_group_id }
              },
              voice_in_trunk: { data: nil }
            }
          )).
          to_return(
            status: 422,
            body: api_fixture('dids/id/patch/assign_voice_in_trunk_group/422'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.relationships[:voice_in_trunk_group] = DIDWW::Resource::VoiceInTrunkGroup.load(id: voice_in_trunk_group_id)

        did.save
        expect(did.errors.count).to eq 1
        expect(did.errors[:voice_in_trunk_group_id]).to contain_exactly('should exist')
      end
    end

    describe 'when Did does not exist for update' do
      it 'raises a NotFound error' do
        id = '46e129f1-deaa-44db-8915-2646de4d4c70'
        stub_didww_request(:patch, "/dids/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'dids',
            attributes: { description: 'test' }
          )).
          to_return(
            status: 404,
            body: api_fixture('dids/id/patch/update_attributes/404'),
            headers: json_api_headers
          )
        did = DIDWW::Resource::Did.load(id: id)
        did.description = 'test'
        expect { did.save }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end
end
