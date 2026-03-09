# frozen_string_literal: true
RSpec.describe DIDWW::Resource::VoiceOutTrunk do
  let(:client) { DIDWW::Client }

  it 'has ON_CLI_MISMATCH_ACTIONS constant' do
    expect(described_class::ON_CLI_MISMATCH_ACTIONS).to include(
      'Reject call', 'Replace CLI', 'Send Original CLI'
    )
  end

  it 'has DEFAULT_DST_ACTIONS constant' do
    expect(described_class::DEFAULT_DST_ACTIONS).to include(
      'Allow Calls', 'Reject Calls'
    )
  end

  it 'has STATUSES constant' do
    expect(described_class::STATUSES).to include('Active', 'Blocked')
  end

  it 'has MEDIA_ENCRYPTION_MODES constant' do
    expect(described_class::MEDIA_ENCRYPTION_MODES).to include(
      'Disable', 'SRTP SDES', 'SRTP DTLS', 'ZRTP'
    )
  end

  describe 'GET /voice_out_trunks' do
    it 'returns a collection of VoiceOutTrunks' do
      stub_didww_request(:get, '/voice_out_trunks').to_return(
        status: 200,
        body: api_fixture('voice_out_trunks/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.voice_out_trunks.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'GET /voice_out_trunks/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    context 'when VoiceOutTrunk exists' do
      let(:trunk) do
        stub_didww_request(:get, "/voice_out_trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('voice_out_trunks/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.voice_out_trunks.find(id).first
      end

      it 'returns a single VoiceOutTrunk' do
        expect(trunk).to be_kind_of(described_class)
        expect(trunk.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"name", type: String' do
          expect(trunk.name).to be_kind_of(String)
        end

        it '"status", type: String' do
          expect(trunk.status).to be_kind_of(String)
          expect(trunk.status).to be_in(described_class::STATUSES)
        end

        it '"capacity_limit", type: Integer' do
          expect(trunk.capacity_limit).to be_kind_of(Integer)
        end

        it '"on_cli_mismatch_action", type: String' do
          expect(trunk.on_cli_mismatch_action).to be_kind_of(String)
        end

        it '"username", type: String' do
          expect(trunk.username).to be_kind_of(String)
        end

        it '"password", type: String' do
          expect(trunk.password).to be_kind_of(String)
        end

        it '"allow_any_did_as_cli", type: Boolean' do
          expect(trunk.allow_any_did_as_cli).to be_in([true, false])
        end

        it '"threshold_reached", type: Boolean' do
          expect(trunk.threshold_reached).to be_in([true, false])
        end

        it '"default_dst_action", type: String' do
          expect(trunk.default_dst_action).to be_kind_of(String)
        end

        it '"media_encryption_mode", type: String' do
          expect(trunk.media_encryption_mode).to be_kind_of(String)
        end

        it '"force_symmetric_rtp", type: Boolean' do
          expect(trunk.force_symmetric_rtp).to be_in([true, false])
        end

        it '"created_at", type: Time' do
          expect(trunk.created_at).to be_kind_of(Time)
        end
      end
    end

    context 'when VoiceOutTrunk does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/voice_out_trunks/#{id}").to_return(
          status: 404,
          body: api_fixture('voice_out_trunks/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.voice_out_trunks.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'POST /voice_out_trunks' do
    describe 'with correct attributes' do
      it 'creates a VoiceOutTrunk' do
        stub_didww_request(:post, '/voice_out_trunks').
          with(body:
            {
              "data": {
                "type": 'voice_out_trunks',
                "attributes": {
                  "name": 'New Outbound Trunk',
                  "allowed_sip_ips": ['10.0.0.1'],
                  "on_cli_mismatch_action": 'Reject call',
                  "capacity_limit": 50,
                  "allow_any_did_as_cli": false,
                  "default_dst_action": 'Allow Calls',
                  "dst_prefixes": ['1', '44'],
                  "media_encryption_mode": 'Disable',
                  "force_symmetric_rtp": false
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('voice_out_trunks/post/create_trunk/201'),
            headers: json_api_headers
          )
        trunk = client.voice_out_trunks.new(
          name: 'New Outbound Trunk',
          allowed_sip_ips: ['10.0.0.1/32'],
          on_cli_mismatch_action: 'Reject call',
          capacity_limit: 50,
          allow_any_did_as_cli: false,
          default_dst_action: 'Allow Calls',
          dst_prefixes: ['1', '44'],
          media_encryption_mode: 'Disable',
          force_symmetric_rtp: false
        )
        trunk.save
        expect(trunk).to be_persisted
      end
    end

    describe 'when name attribute already been taken' do
      it 'returns a VoiceOutTrunk with errors' do
        stub_didww_request(:post, '/voice_out_trunks').
          with(body:
            {
              "data": {
                "type": 'voice_out_trunks',
                "attributes": {
                  "name": 'New Outbound Trunk',
                  "capacity_limit": 50
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('voice_out_trunks/post/create_trunk/422'),
            headers: json_api_headers
          )
        trunk = client.voice_out_trunks.new(
          name: 'New Outbound Trunk',
          capacity_limit: 50
        )
        trunk.save
        expect(trunk).not_to be_persisted
        expect(trunk.errors.count).to eq 1
        expect(trunk.errors[:name]).to contain_exactly('has already been taken')
      end
    end
  end

  describe 'PATCH /voice_out_trunks/{id}' do
    describe 'with correct attributes' do
      it 'updates a VoiceOutTrunk' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body:
            {
              "data": {
                "id": id,
                "type": 'voice_out_trunks',
                "attributes": {
                  "name": 'Updated Trunk',
                  "capacity_limit": 200
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id).tap do |t|
          t.name = 'Updated Trunk'
          t.capacity_limit = 200
        end
        expect(trunk.save)
        expect(trunk.errors).to be_empty
        expect(trunk.name).to eq('Updated Trunk')
        expect(trunk.capacity_limit).to eq(200)
      end

      it 'sends only dirty attributes in PATCH' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: {
            data: {
              id: id,
              type: 'voice_out_trunks',
              attributes: {
                name: 'Only Name Changed'
              }
            }
          }.to_json).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/200'),
            headers: json_api_headers
          )

        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        expect(trunk).not_to be_changed
        trunk.name = 'Only Name Changed'
        expect(trunk).to be_changed
        expect(trunk.changed).to eq(['name'])
        trunk.save

        expect(request).to have_been_made.once
      end

      it 'sends explicit null when attribute is set to nil' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: {
            data: {
              id: id,
              type: 'voice_out_trunks',
              attributes: {
                callback_url: nil
              }
            }
          }.to_json).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/200'),
            headers: json_api_headers
          )

        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.callback_url = nil
        trunk.save

        expect(request).to have_been_made.once
      end
    end

    describe 'when name attribute already been taken' do
      it 'returns a VoiceOutTrunk with errors' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body:
            {
              "data": {
                "id": id,
                "type": 'voice_out_trunks',
                "attributes": {
                  "name": 'Duplicate Name'
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/422'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.name = 'Duplicate Name'
        trunk.save
        expect(trunk.errors.count).to eq 1
        expect(trunk.errors[:name]).to contain_exactly('has already been taken')
      end
    end

    context 'when VoiceOutTrunk does not exist' do
      it 'raises a NotFound error' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body:
            {
              "data": {
                "id": id,
                "type": 'voice_out_trunks',
                "attributes": {
                  "name": 'Updated Trunk'
                }
              }
            }.to_json).
          to_return(
            status: 404,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/404'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.name = 'Updated Trunk'
        expect { trunk.save }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'DELETE /voice_out_trunks/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'deletes a VoiceOutTrunk' do
      stub_didww_request(:delete, "/voice_out_trunks/#{id}").
        to_return(
          status: 204,
          body: api_fixture('voice_out_trunks/id/delete/delete_trunk/204'),
          headers: json_api_headers
        )
      trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
      expect(trunk.destroy)
      expect(WebMock).to have_requested(:delete, api_uri("/voice_out_trunks/#{id}"))
    end

    context 'when VoiceOutTrunk does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:delete, "/voice_out_trunks/#{id}").
          to_return(
            status: 404,
            body: api_fixture('voice_out_trunks/id/delete/delete_trunk/404'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        expect { trunk.destroy }.to raise_error(JsonApiClient::Errors::NotFound)
        expect(WebMock).to have_requested(:delete, api_uri("/voice_out_trunks/#{id}"))
      end
    end
  end
end
