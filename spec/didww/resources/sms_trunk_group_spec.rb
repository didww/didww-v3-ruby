# frozen_string_literal: true
RSpec.describe DIDWW::Resource::SmsTrunkGroup do
  let(:client) { DIDWW::Client }
  let(:id) { '2b3c4d5e-0001-4b6c-9d7e-8f9a0b1c2d01' }
  let(:http_in_trunk_id) { '1a2b3c4d-0002-4a5b-8c6d-7e8f9a0b1c02' }
  let(:smpp_smsc_trunk_id) { '1a2b3c4d-0005-4a5b-8c6d-7e8f9a0b1c05' }

  describe 'GET /sms_trunk_groups' do
    let(:groups) do
      stub_didww_request(:get, '/sms_trunk_groups').to_return(
        status: 200,
        body: api_fixture('sms_trunk_groups/get/without_includes/200'),
        headers: json_api_headers
      )
      client.sms_trunk_groups.all
    end

    it 'returns a collection of SmsTrunkGroups' do
      expect(groups).to all be_an_instance_of(described_class)
    end

    describe 'has correct attributes' do
      it '"name", type: String' do
        expect(groups.first.name).to eq('Inbound SMS')
      end
      it '"external_reference_id", type: String' do
        expect(groups.first.external_reference_id).to be_nil
      end
      it '"created_at" and "updated_at", type: Time' do
        expect(groups.first.created_at).to be_kind_of(Time)
        expect(groups.first.updated_at).to be_kind_of(Time)
      end
    end

    it 'reads sms_trunks_count from meta' do
      expect(groups.map(&:sms_trunks_count)).to eq([2, 0])
    end

    it 'returns nil sms_trunks_count for a group without meta' do
      expect(described_class.new(name: 'Main').sms_trunks_count).to be_nil
    end
  end

  describe 'GET /sms_trunk_groups/{id}' do
    it 'optionally includes SmsTrunks' do
      stub_didww_request(:get, "/sms_trunk_groups/#{id}?include=sms_trunks").to_return(
        status: 200,
        body: api_fixture('sms_trunk_groups/id/get/with_included_sms_trunks/200'),
        headers: json_api_headers
      )
      group = client.sms_trunk_groups.includes(:sms_trunks).find(id).first
      expect(group.sms_trunks).to all be_an_instance_of(DIDWW::Resource::SmsTrunk)
      expect(group.sms_trunks.map(&:id)).to eq([http_in_trunk_id, smpp_smsc_trunk_id])
      expect(group.relationships[:incoming_dids]).to be
    end

    context 'when SmsTrunkGroup does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/sms_trunk_groups/#{id}").to_return(
          status: 404,
          body: api_fixture('sms_trunk_groups/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.sms_trunk_groups.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'POST /sms_trunk_groups' do
    it 'creates an SmsTrunkGroup with SmsTrunks' do
      stub_didww_request(:post, '/sms_trunk_groups').
        with(body: {
          data: {
            type: 'sms_trunk_groups',
            relationships: {
              sms_trunks: { data: [{ type: 'sms_trunks', id: http_in_trunk_id }] }
            },
            attributes: { name: 'Inbound SMS' }
          }
        }.to_json).
        to_return(
          status: 201,
          body: api_fixture('sms_trunk_groups/post/create/201'),
          headers: json_api_headers
        )
      group = client.sms_trunk_groups.new(name: 'Inbound SMS')
      group.relationships.sms_trunks = [DIDWW::Resource::SmsTrunk.load(id: http_in_trunk_id)]
      group.save
      expect(group).to be_persisted
      expect(group.sms_trunks_count).to eq(1)
    end
  end

  describe 'PATCH /sms_trunk_groups/{id}' do
    it 'replaces the SmsTrunks membership' do
      stub_didww_request(:patch, "/sms_trunk_groups/#{id}").
        with(body: json_api_body(
          id: id,
          type: 'sms_trunk_groups',
          relationships: {
            sms_trunks: {
              data: [
                { type: 'sms_trunks', id: http_in_trunk_id },
                { type: 'sms_trunks', id: smpp_smsc_trunk_id }
              ]
            }
          }
        )).
        to_return(
          status: 200,
          body: api_fixture('sms_trunk_groups/id/patch/update_sms_trunks/200'),
          headers: json_api_headers
        )
      group = described_class.load(id: id)
      group.relationships.sms_trunks = [
        DIDWW::Resource::SmsTrunk.load(id: http_in_trunk_id),
        DIDWW::Resource::SmsTrunk.load(id: smpp_smsc_trunk_id)
      ]
      expect(group.save).to eq(true)
      expect(group.sms_trunks_count).to eq(2)
    end
  end

  describe 'DELETE /sms_trunk_groups/{id}' do
    it 'deletes an SmsTrunkGroup' do
      stub_didww_request(:delete, "/sms_trunk_groups/#{id}").to_return(
        status: 204,
        body: api_fixture('sms_trunk_groups/id/delete/delete_group/204'),
        headers: json_api_headers
      )
      expect(described_class.load(id: id).destroy).to eq(true)
      expect(WebMock).to have_requested(:delete, api_uri("/sms_trunk_groups/#{id}"))
    end

    context 'when DIDs are routed to the group or its trunks' do
      it 'returns an SmsTrunkGroup with errors' do
        stub_didww_request(:delete, "/sms_trunk_groups/#{id}").to_return(
          status: 422,
          body: api_fixture('sms_trunk_groups/id/delete/delete_group/422'),
          headers: json_api_headers
        )
        group = described_class.load(id: id)
        expect(group.destroy).to eq(false)
        expect(group.errors[:base]).to contain_exactly('is in use')
      end
    end
  end

  it_behaves_like 'a resource that PATCHes external_reference_id',
                  resource_type: 'sms_trunk_groups',
                  path_prefix: 'sms_trunk_groups',
                  id: '2b3c4d5e-0001-4b6c-9d7e-8f9a0b1c2d01'
end
