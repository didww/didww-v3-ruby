# frozen_string_literal: true
RSpec.describe DIDWW::Resource::VoiceOutTrunk do
  let(:client) { DIDWW::Client }

  it 'has ON_CLI_MISMATCH_ACTIONS constant' do
    expect(described_class::ON_CLI_MISMATCH_ACTIONS).to include(
      'reject_call', 'replace_cli', 'randomize_cli', 'send_original_cli'
    )
  end

  it 'has DEFAULT_DST_ACTIONS constant' do
    expect(described_class::DEFAULT_DST_ACTIONS).to include(
      'allow_all', 'reject_all'
    )
  end

  it 'has STATUSES constant' do
    expect(described_class::STATUSES).to include('active', 'blocked')
  end

  describe 'status helpers' do
    it 'exposes #active? predicate' do
      trunk = described_class.new(status: 'active')
      expect(trunk.active?).to be true
      trunk.status = 'blocked'
      expect(trunk.active?).to be false
    end

    it 'exposes #blocked? predicate' do
      trunk = described_class.new(status: 'blocked')
      expect(trunk.blocked?).to be true
      trunk.status = 'active'
      expect(trunk.blocked?).to be false
    end
  end

  it 'has MEDIA_ENCRYPTION_MODES constant' do
    expect(described_class::MEDIA_ENCRYPTION_MODES).to include(
      'disabled', 'srtp_sdes', 'srtp_dtls', 'zrtp'
    )
  end

  describe 'authentication_method (2026-04-16 polymorphic)' do
    let(:property_names) do
      [].tap { |names| described_class.schema.each_property { |p| names << p.name } }
    end

    it 'declares authentication_method' do
      expect(property_names).to include(:authentication_method)
    end

    it 'no longer declares the flat allowed_sip_ips/username/password attributes' do
      expect(property_names).not_to include(:allowed_sip_ips, :username, :password)
    end
  end

  describe 'emergency_dids relationship (2026-04-16)' do
    it 'has an emergency_dids has_many relationship' do
      trunk = described_class.new
      expect(trunk).to respond_to(:emergency_dids)
    end
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

        it '"authentication_method", polymorphic complex object' do
          expect(trunk.authentication_method).to be_kind_of(
            DIDWW::ComplexObject::AuthenticationMethod::Base
          )
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

        it '"external_reference_id", type: String' do
          expect(trunk.external_reference_id).to be_kind_of(String).or be_nil
        end

        it '"emergency_enable_all", type: Boolean' do
          expect(trunk.emergency_enable_all).to be_in([true, false])
        end

        it '"rtp_timeout", type: Integer' do
          expect(trunk.rtp_timeout).to be_kind_of(Integer)
        end
      end
    end

    context 'when VoiceOutTrunk has ip_only authentication_method' do
      let(:ip_only_id) { '23fd58f9-9094-406c-bfd9-f4d25bda13c6' }
      let(:trunk) do
        stub_didww_request(:get, "/voice_out_trunks/#{ip_only_id}").to_return(
          status: 200,
          body: api_fixture('voice_out_trunks/id/get/show_ip_only/200'),
          headers: json_api_headers
        )
        client.voice_out_trunks.find(ip_only_id).first
      end

      it 'returns a VoiceOutTrunk with IpOnly authentication_method' do
        expect(trunk).to be_kind_of(described_class)
        expect(trunk.id).to eq(ip_only_id)
      end

      it 'deserializes authentication_method as IpOnly' do
        expect(trunk.authentication_method).to be_kind_of(
          DIDWW::ComplexObject::AuthenticationMethod::IpOnly
        )
        expect(trunk.authentication_method).not_to be_kind_of(
          DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp
        )
      end

      it 'has correct allowed_sip_ips' do
        expect(trunk.authentication_method.allowed_sip_ips).to eq(['203.0.113.1/32'])
      end

      it 'does not have username or password' do
        expect(trunk.authentication_method).not_to respond_to(:username)
        expect(trunk.authentication_method).not_to respond_to(:password)
      end
    end

    context 'when VoiceOutTrunk has twilio authentication_method' do
      let(:twilio_id) { 'b5e701f4-ea15-4f9d-8f35-6a0bdce04385' }
      let(:trunk) do
        stub_didww_request(:get, "/voice_out_trunks/#{twilio_id}").to_return(
          status: 200,
          body: api_fixture('voice_out_trunks/id/get/show_twilio/200'),
          headers: json_api_headers
        )
        client.voice_out_trunks.find(twilio_id).first
      end

      it 'returns a VoiceOutTrunk with Twilio authentication_method' do
        expect(trunk).to be_kind_of(described_class)
        expect(trunk.id).to eq(twilio_id)
        expect(trunk.name).to eq('SDK Test twilio')
      end

      it 'deserializes authentication_method as Twilio' do
        expect(trunk.authentication_method).to be_kind_of(
          DIDWW::ComplexObject::AuthenticationMethod::Twilio
        )
        expect(trunk.authentication_method.type).to eq('twilio')
      end

      it 'has correct twilio_account_sid' do
        expect(trunk.authentication_method.twilio_account_sid).to eq('AC22222222222222222222222222222222')
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
    let(:trunk_name) { 'New Outbound Trunk' }

    describe 'with correct attributes' do
      it 'creates a VoiceOutTrunk with a credentials_and_ip authentication_method' do
        stub_didww_request(:post, '/voice_out_trunks').
          with(body: json_api_post_body(
            type: 'voice_out_trunks',
            attributes: {
              name: trunk_name,
              on_cli_mismatch_action: 'reject_call',
              capacity_limit: 50,
              allow_any_did_as_cli: false,
              default_dst_action: 'allow_all',
              dst_prefixes: ['1', '44'],
              media_encryption_mode: 'disabled',
              force_symmetric_rtp: false,
              authentication_method: {
                type: 'credentials_and_ip',
                attributes: {
                  allowed_sip_ips: ['203.0.113.1/32'],
                  tech_prefix: ''
                }
              }
            }
          )).
          to_return(
            status: 201,
            body: api_fixture('voice_out_trunks/post/create_trunk/201'),
            headers: json_api_headers
          )
        trunk = client.voice_out_trunks.new(
          name: trunk_name,
          on_cli_mismatch_action: 'reject_call',
          capacity_limit: 50,
          allow_any_did_as_cli: false,
          default_dst_action: 'allow_all',
          dst_prefixes: ['1', '44'],
          media_encryption_mode: 'disabled',
          force_symmetric_rtp: false,
          authentication_method: DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp.new(
            allowed_sip_ips: ['203.0.113.1/32'],
            tech_prefix: ''
          )
        )
        trunk.save
        expect(trunk).to be_persisted
      end
    end

    describe 'with twilio authentication_method' do
      it 'creates a VoiceOutTrunk with a twilio authentication_method' do
        stub_didww_request(:post, '/voice_out_trunks').
          with(body: json_api_post_body(
            type: 'voice_out_trunks',
            attributes: {
              name: 'SDK Test twilio create',
              on_cli_mismatch_action: 'reject_call',
              authentication_method: {
                type: 'twilio',
                attributes: {
                  twilio_account_sid: 'AC33333333333333333333333333333333'
                }
              }
            }
          )).
          to_return(
            status: 201,
            body: api_fixture('voice_out_trunks/post/create_twilio/201'),
            headers: json_api_headers
          )
        trunk = client.voice_out_trunks.new(
          name: 'SDK Test twilio create',
          on_cli_mismatch_action: 'reject_call',
          authentication_method: DIDWW::ComplexObject::AuthenticationMethod::Twilio.new(
            twilio_account_sid: 'AC33333333333333333333333333333333'
          )
        )
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.authentication_method).to be_kind_of(
          DIDWW::ComplexObject::AuthenticationMethod::Twilio
        )
        expect(trunk.authentication_method.twilio_account_sid).to eq('AC33333333333333333333333333333333')
      end
    end

    describe 'when name attribute already been taken' do
      it 'returns a VoiceOutTrunk with errors' do
        stub_didww_request(:post, '/voice_out_trunks').
          with(body: json_api_post_body(
            type: 'voice_out_trunks',
            attributes: {
              name: trunk_name,
              capacity_limit: 50
            }
          )).
          to_return(
            status: 422,
            body: api_fixture('voice_out_trunks/post/create_trunk/422'),
            headers: json_api_headers
          )
        trunk = client.voice_out_trunks.new(
          name: trunk_name,
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
    let(:updated_trunk_name) { 'Updated Trunk' }

    describe 'with correct attributes' do
      it 'updates a VoiceOutTrunk' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: {
              name: updated_trunk_name,
              capacity_limit: 200
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id).tap do |t|
          t.name = updated_trunk_name
          t.capacity_limit = 200
        end
        expect(trunk.save)
        expect(trunk.errors).to be_empty
        expect(trunk.name).to eq(updated_trunk_name)
        expect(trunk.capacity_limit).to eq(200)
      end

      it 'sends only dirty attributes in PATCH' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: { name: 'Only Name Changed' }
          )).
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

      it 'PATCHes only authentication_method when the polymorphic method is reassigned' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: {
              authentication_method: {
                type: 'credentials_and_ip',
                attributes: {
                  allowed_sip_ips: ['192.0.2.10/32'],
                  tech_prefix: '99'
                }
              }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/200'),
            headers: json_api_headers
          )

        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        expect(trunk).not_to be_changed

        trunk.authentication_method =
          DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp.new(
            allowed_sip_ips: ['192.0.2.10/32'],
            tech_prefix: '99'
          )

        expect(trunk).to be_changed
        expect(trunk.changed).to eq(['authentication_method'])
        trunk.save

        expect(request).to have_been_made.once
      end

      it 'sends explicit null when attribute is set to nil' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: { callback_url: nil }
          )).
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

      it 'toggles emergency_enable_all attribute' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: { emergency_enable_all: true }
          )).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/200'),
            headers: json_api_headers
          )

        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.emergency_enable_all = true
        trunk.save

        expect(request).to have_been_made.once
      end

      it 'replaces the emergency_dids to-many relationship' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        did_a = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        did_b = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            relationships: {
              emergency_dids: {
                data: [
                  { type: 'dids', id: did_a },
                  { type: 'dids', id: did_b }
                ]
              }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_emergency_dids/200'),
            headers: json_api_headers
          )

        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.relationships[:emergency_dids] = [
          DIDWW::Resource::Did.load(id: did_a),
          DIDWW::Resource::Did.load(id: did_b)
        ]
        trunk.save

        expect(request).to have_been_made.once
      end

      it 'clears the emergency_dids to-many relationship with an empty array' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        request = stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            relationships: {
              emergency_dids: { data: [] }
            }
          )).
          to_return(
            status: 200,
            body: api_fixture('voice_out_trunks/id/patch/update_emergency_dids/200'),
            headers: json_api_headers
          )

        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.relationships[:emergency_dids] = []
        trunk.save

        expect(request).to have_been_made.once
      end
    end

    describe 'when name attribute already been taken' do
      it 'returns a VoiceOutTrunk with errors' do
        id = '01234567-89ab-cdef-0123-456789abcdef'
        stub_didww_request(:patch, "/voice_out_trunks/#{id}").
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: { name: 'Duplicate Name' }
          )).
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
          with(body: json_api_body(
            id: id,
            type: 'voice_out_trunks',
            attributes: { name: updated_trunk_name }
          )).
          to_return(
            status: 404,
            body: api_fixture('voice_out_trunks/id/patch/update_attributes/404'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::VoiceOutTrunk.load(id: id)
        trunk.name = updated_trunk_name
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
