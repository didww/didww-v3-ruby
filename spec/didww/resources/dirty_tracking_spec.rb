# frozen_string_literal: true
RSpec.describe 'Dirty tracking' do
  let(:client) { DIDWW::Client }
  let(:did_id) { '44957076-778a-4802-b60c-d22db0cda284' }

  describe 'PATCH /dids/{id} sends only dirty attributes' do
    let(:patch_response) do
      {
        status: 200,
        body: api_fixture('dids/id/patch/update_attributes/200'),
        headers: json_api_headers
      }
    end

    it 'sends only the single changed attribute' do
      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            attributes: {
              description: 'updated'
            }
          }
        }.to_json).
        to_return(patch_response)

      did = DIDWW::Resource::Did.load(id: did_id)
      did.description = 'updated'
      did.save

      expect(request).to have_been_made.once
    end

    it 'sends multiple changed attributes but no unchanged ones' do
      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            attributes: {
              capacity_limit: 2,
              description: 'something'
            }
          }
        }.to_json).
        to_return(patch_response)

      did = DIDWW::Resource::Did.load(id: did_id)
      did.capacity_limit = 2
      did.description = 'something'
      did.save

      expect(request).to have_been_made.once
    end

    it 'sends explicit null when attribute is set to nil' do
      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            attributes: {
              description: nil
            }
          }
        }.to_json).
        to_return(patch_response)

      did = DIDWW::Resource::Did.load(id: did_id)
      did.description = nil
      did.save

      expect(request).to have_been_made.once
    end

    it 'sends terminated as only attribute' do
      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            attributes: {
              terminated: true
            }
          }
        }.to_json).
        to_return(patch_response)

      did = DIDWW::Resource::Did.load(id: did_id)
      did.terminated = true
      did.save

      expect(request).to have_been_made.once
    end
  end

  describe 'PATCH /dids/{id} from API-loaded resource sends only dirty' do
    let(:patch_response) do
      {
        status: 200,
        body: api_fixture('dids/id/patch/update_attributes/200'),
        headers: json_api_headers
      }
    end

    it 'sends only the modified attribute after loading from API' do
      stub_didww_request(:get, "/dids/#{did_id}").to_return(
        status: 200,
        body: api_fixture('dids/id/get/without_includes/200'),
        headers: json_api_headers
      )

      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            attributes: {
              description: 'patched from loaded resource'
            }
          }
        }.to_json).
        to_return(patch_response)

      did = client.dids.find(did_id).first
      did.description = 'patched from loaded resource'
      did.save

      expect(request).to have_been_made.once
    end
  end

  describe 'PATCH /dids/{id} with relationship changes' do
    let(:patch_response) do
      {
        status: 200,
        body: api_fixture('dids/id/patch/assign_voice_in_trunk/200'),
        headers: json_api_headers
      }
    end

    it 'sends voice_in_trunk and auto-nullifies voice_in_trunk_group' do
      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            relationships: {
              voice_in_trunk: {
                data: {
                  type: 'voice_in_trunks',
                  id: 'c80d096a-c8cf-4449-aa6d-8bac39130fe0'
                }
              },
              voice_in_trunk_group: {
                data: nil
              }
            },
            attributes: {}
          }
        }.to_json).
        to_return(patch_response)

      did = DIDWW::Resource::Did.load(id: did_id)
      did.relationships[:voice_in_trunk] = DIDWW::Resource::VoiceInTrunk.load(id: 'c80d096a-c8cf-4449-aa6d-8bac39130fe0')
      did.save

      expect(request).to have_been_made.once
    end

    it 'sends voice_in_trunk_group and auto-nullifies voice_in_trunk' do
      request = stub_didww_request(:patch, "/dids/#{did_id}").
        with(body: {
          data: {
            id: did_id,
            type: 'dids',
            relationships: {
              voice_in_trunk_group: {
                data: {
                  type: 'voice_in_trunk_groups',
                  id: '1dc6e448-d9d8-4da8-a34b-21459b03112f'
                }
              },
              voice_in_trunk: {
                data: nil
              }
            },
            attributes: {}
          }
        }.to_json).
        to_return(patch_response)

      did = DIDWW::Resource::Did.load(id: did_id)
      did.relationships[:voice_in_trunk_group] = DIDWW::Resource::VoiceInTrunkGroup.load(id: '1dc6e448-d9d8-4da8-a34b-21459b03112f')
      did.save

      expect(request).to have_been_made.once
    end
  end

  describe 'dirty tracking helper methods' do
    describe DIDWW::Resource::Did do
      it 'starts clean after load' do
        did = described_class.load(id: 'abc')
        expect(did).not_to be_changed
        expect(did.changed).to be_empty
      end

      it 'tracks changed attributes' do
        did = described_class.load(id: 'abc')
        did.capacity_limit = 20
        expect(did).to be_changed
        expect(did.changed).to eq(['capacity_limit'])
        expect(did.attribute_changed?('capacity_limit')).to be true
        expect(did.attribute_changed?('description')).to be false
      end

      it 'reports attribute_was after loading with attributes' do
        did = described_class.new(
          id: 'abc',
          capacity_limit: 10,
          description: 'original'
        )
        did.clear_changes_information
        did.capacity_limit = 20
        expect(did.attribute_was('capacity_limit')).to eq(10)
        expect(did.attribute_change('capacity_limit')).to eq([10, 20])
      end
    end

    describe DIDWW::Resource::VoiceInTrunk do
      it 'tracks changed attributes after load' do
        trunk = described_class.load(id: 't1')
        expect(trunk).not_to be_changed
        trunk.name = 'updated'
        expect(trunk).to be_changed
        expect(trunk.changed).to eq(['name'])
      end
    end

    describe DIDWW::Resource::VoiceInTrunkGroup do
      it 'tracks changed attributes after load' do
        group = described_class.load(id: 'g1')
        expect(group).not_to be_changed
        group.name = 'updated'
        expect(group).to be_changed
        expect(group.changed).to eq(['name'])
      end
    end

    describe DIDWW::Resource::VoiceOutTrunk do
      it 'tracks changed attributes after load' do
        trunk = described_class.load(id: 't1')
        expect(trunk).not_to be_changed
        trunk.name = 'updated'
        expect(trunk).to be_changed
        expect(trunk.changed).to eq(['name'])
      end
    end

    describe DIDWW::Resource::SharedCapacityGroup do
      it 'tracks changed attributes after load' do
        group = described_class.load(id: 'g1')
        expect(group).not_to be_changed
        group.name = 'updated'
        expect(group).to be_changed
        expect(group.changed).to eq(['name'])
      end
    end
  end
end
