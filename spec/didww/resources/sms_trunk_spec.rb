# frozen_string_literal: true
RSpec.describe DIDWW::Resource::SmsTrunk do
  let(:client) { DIDWW::Client }
  let(:configurations) { DIDWW::ComplexObject::SmsTrunkConfiguration }

  describe 'GET /sms_trunks/{id}' do
    let(:id) { '1a2b3c4d-0003-4a5b-8c6d-7e8f9a0b1c03' }

    context 'when SmsTrunk exists' do
      let(:trunk) do
        stub_didww_request(:get, "/sms_trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('sms_trunks/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.sms_trunks.find(id).first
      end

      it 'returns a single SmsTrunk' do
        expect(trunk).to be_kind_of(described_class)
        expect(trunk.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"name", type: String' do
          expect(trunk.name).to eq('http_out trunk')
        end
        it '"external_reference_id", type: String' do
          expect(trunk.external_reference_id).to be_nil
        end
        it '"blocked", type: Boolean' do
          expect(trunk.blocked).to eq(false)
        end
        it '"priority", type: Integer' do
          expect(trunk.priority).to be_nil
        end
        it '"allow_any_did_as_source", type: Boolean' do
          expect(trunk.allow_any_did_as_source).to eq(false)
        end
        it '"allow_in" and "allow_out", type: Boolean' do
          expect(trunk.allow_in).to eq(false)
          expect(trunk.allow_out).to eq(true)
        end
        it '"created_at" and "updated_at", type: Time' do
          expect(trunk.created_at).to be_kind_of(Time)
          expect(trunk.updated_at).to be_kind_of(Time)
        end
        it '"configuration", type: HttpOut' do
          expect(trunk.configuration).to be_an_instance_of(configurations::HttpOut)
          expect(trunk.configuration.callback_url).to eq('https://example.com/sms/status')
          expect(trunk.configuration.allowed_ips).to eq(['203.0.113.10'])
          expect(trunk.configuration.auth_name).to eq('generated-name')
          expect(trunk.configuration.auth_password).to eq('generated-password')
        end
      end

      it 'reads the submit host from meta' do
        expect(trunk.host).to eq('https://sms-out.example.com/outbound_messages')
      end

      it 'has outgoing_dids, incoming_dids and sms_trunk_group relationships' do
        expect(trunk.relationships[:outgoing_dids]).to be
        expect(trunk.relationships[:incoming_dids]).to be
        expect(trunk.relationships[:sms_trunk_group]).to be
      end
    end

    context 'when SmsTrunk does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/sms_trunks/#{id}").to_return(
          status: 404,
          body: api_fixture('sms_trunks/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.sms_trunks.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'GET /sms_trunks' do
    it 'returns a collection of SmsTrunks with typed configurations' do
      stub_didww_request(:get, '/sms_trunks').to_return(
        status: 200,
        body: api_fixture('sms_trunks/get/without_includes/200'),
        headers: json_api_headers
      )
      trunks = client.sms_trunks.all
      expect(trunks).to all be_an_instance_of(described_class)
      expect(trunks.map { |trunk| trunk.configuration.class }).to eq(
        [
          configurations::SmsToEmail,
          configurations::HttpIn,
          configurations::HttpOut,
          configurations::SmppEsme,
          configurations::SmppSmsc
        ]
      )
      expect(trunks.map(&:host)).to eq([nil, nil, 'https://sms-out.example.com/outbound_messages', nil, nil])
    end

    it 'filters, sorts and optionally includes SmsTrunkGroup' do
      stub_didww_request(:get, '/sms_trunks?filter[configuration.type]=http_in&include=sms_trunk_group&sort=-priority').to_return(
        status: 200,
        body: api_fixture('sms_trunks/get/with_included_sms_trunk_group/200'),
        headers: json_api_headers
      )
      trunks = client.sms_trunks.where('configuration.type': 'http_in').includes(:sms_trunk_group).order(priority: :desc).all
      expect(trunks.first.sms_trunk_group).to be_an_instance_of(DIDWW::Resource::SmsTrunkGroup)
      expect(trunks.first.sms_trunk_group.sms_trunks_count).to eq(1)
    end
  end

  describe 'POST /sms_trunks' do
    {
      'sms_to_email' => {
        send_to: 'sms@example.com',
        subject: 'Inbound SMS',
        message: 'You have a new message.'
      },
      'http_in' => {
        url: 'https://example.com/sms',
        http_method: 'post',
        body_type: 'json',
        body: '{"text":"{SMS_TEXT}","from":"{SMS_SRC_ADDR}"}'
      },
      'http_out' => {
        callback_url: 'https://example.com/sms/status',
        allowed_ips: ['203.0.113.10']
      },
      'smpp_esme' => {
        allowed_ips: ['203.0.113.10'],
        server_location: 'nyc'
      },
      'smpp_smsc' => {
        host: 'smsc.example.com',
        tx_port: 2775,
        rx_port: 2776,
        transceiver_mode: true,
        connection_timeout: 30,
        use_ssl: false,
        system_id: 'didww',
        password: 'secret',
        server_location: 'nyc'
      }
    }.each do |type, config_attributes|
      it "creates an #{type} SmsTrunk" do
        stub_didww_request(:post, '/sms_trunks').
          with(body: json_api_post_body(
            type: 'sms_trunks',
            attributes: {
              name: "#{type} trunk",
              configuration: { type: type, attributes: config_attributes }
            }
          )).
          to_return(
            status: 201,
            body: api_fixture("sms_trunks/post/create_#{type}/201"),
            headers: json_api_headers
          )
        configuration = DIDWW::ComplexObject::SmsTrunkConfiguration::TYPE_CLASSES.fetch(type).new(config_attributes)
        trunk = client.sms_trunks.new(name: "#{type} trunk", configuration: configuration)
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_an_instance_of(configuration.class)
      end
    end

    it 'creates an SmsTrunk assigned to an SmsTrunkGroup with outgoing DIDs' do
      group_id = '2b3c4d5e-0001-4b6c-9d7e-8f9a0b1c2d01'
      did_id = '9d8c7b6a-0001-4f3e-9d2c-1b0a9f8e7d01'
      stub_didww_request(:post, '/sms_trunks').
        with(body: {
          data: {
            type: 'sms_trunks',
            relationships: {
              sms_trunk_group: { data: { type: 'sms_trunk_groups', id: group_id } },
              outgoing_dids: { data: [{ type: 'dids', id: did_id }] }
            },
            attributes: {
              name: 'smpp_smsc trunk',
              configuration: { type: 'smpp_smsc', attributes: { host: 'smsc.example.com' } }
            }
          }
        }.to_json).
        to_return(
          status: 201,
          body: api_fixture('sms_trunks/post/create_smpp_smsc/201'),
          headers: json_api_headers
        )
      trunk = client.sms_trunks.new(
        name: 'smpp_smsc trunk',
        configuration: configurations::SmppSmsc.new(host: 'smsc.example.com')
      )
      trunk.relationships.sms_trunk_group = DIDWW::Resource::SmsTrunkGroup.load(id: group_id)
      trunk.relationships.outgoing_dids = [DIDWW::Resource::Did.load(id: did_id)]
      trunk.save
      expect(trunk).to be_persisted
    end

    it 'returns an SmsTrunk with errors' do
      stub_didww_request(:post, '/sms_trunks').
        with(body: json_api_post_body(
          type: 'sms_trunks',
          attributes: { name: 'sms_to_email trunk', configuration: { type: 'sms_to_email', attributes: {} } }
        )).
        to_return(
          status: 422,
          body: api_fixture('sms_trunks/post/create_sms_to_email/422'),
          headers: json_api_headers
        )
      trunk = client.sms_trunks.new(name: 'sms_to_email trunk', configuration: configurations::SmsToEmail.new)
      trunk.save
      expect(trunk).not_to be_persisted
      expect(trunk.errors[:configuration]).to contain_exactly("can't be blank")
    end
  end

  describe 'PATCH /sms_trunks/{id}' do
    let(:id) { '1a2b3c4d-0002-4a5b-8c6d-7e8f9a0b1c02' }

    it 'updates name and configuration members of the same type' do
      stub_didww_request(:patch, "/sms_trunks/#{id}").
        with(body: json_api_body(
          id: id,
          type: 'sms_trunks',
          attributes: {
            name: 'Webhook',
            configuration: { type: 'http_in', attributes: { url: 'https://example.com/sms/v2' } }
          }
        )).
        to_return(
          status: 200,
          body: api_fixture('sms_trunks/id/patch/update_http_in/200'),
          headers: json_api_headers
        )
      trunk = described_class.load(id: id)
      trunk.name = 'Webhook'
      trunk.configuration = configurations::HttpIn.new(url: 'https://example.com/sms/v2')
      expect(trunk.save).to eq(true)
      expect(trunk.name).to eq('Webhook')
      expect(trunk.configuration).to be_an_instance_of(configurations::HttpIn)
      expect(trunk.configuration.url).to eq('https://example.com/sms/v2')
      expect(trunk.configuration.http_method).to eq(configurations::HttpIn::HTTP_METHOD_POST)
    end

    it 'does not send the generated credentials back' do
      http_out_id = '1a2b3c4d-0003-4a5b-8c6d-7e8f9a0b1c03'
      stub_didww_request(:get, "/sms_trunks/#{http_out_id}").to_return(
        status: 200,
        body: api_fixture('sms_trunks/id/get/without_includes/200'),
        headers: json_api_headers
      )
      request = stub_didww_request(:patch, "/sms_trunks/#{http_out_id}").
        with(body: json_api_body(
          id: http_out_id,
          type: 'sms_trunks',
          attributes: {
            configuration: {
              type: 'http_out',
              attributes: { callback_url: 'https://example.com/sms/status/v2', allowed_ips: ['203.0.113.10'] }
            }
          }
        )).
        to_return(
          status: 200,
          body: api_fixture('sms_trunks/id/get/without_includes/200'),
          headers: json_api_headers
        )
      trunk = client.sms_trunks.find(http_out_id).first
      trunk.configuration = configurations::HttpOut.new(
        trunk.configuration.attributes.merge(callback_url: 'https://example.com/sms/status/v2')
      )
      trunk.save
      expect(request).to have_been_made.once
    end
  end

  describe 'DELETE /sms_trunks/{id}' do
    let(:id) { '1a2b3c4d-0002-4a5b-8c6d-7e8f9a0b1c02' }

    it 'deletes an SmsTrunk' do
      stub_didww_request(:delete, "/sms_trunks/#{id}").to_return(
        status: 204,
        body: api_fixture('sms_trunks/id/delete/delete_trunk/204'),
        headers: json_api_headers
      )
      expect(described_class.load(id: id).destroy).to eq(true)
      expect(WebMock).to have_requested(:delete, api_uri("/sms_trunks/#{id}"))
    end

    context 'when DIDs are routed to the trunk' do
      it 'returns an SmsTrunk with errors' do
        stub_didww_request(:delete, "/sms_trunks/#{id}").to_return(
          status: 422,
          body: api_fixture('sms_trunks/id/delete/delete_trunk/422'),
          headers: json_api_headers
        )
        trunk = described_class.load(id: id)
        expect(trunk.destroy).to eq(false)
        expect(trunk.errors[:base]).to contain_exactly('is in use')
      end
    end
  end

  describe '#regenerate_credentials' do
    let(:id) { '1a2b3c4d-0004-4a5b-8c6d-7e8f9a0b1c04' }

    it 'POSTs an sms_trunk_regenerate_credentials resource for the trunk' do
      request = stub_didww_request(:post, '/sms_trunk_regenerate_credentials').
        with(body: {
          data: {
            type: 'sms_trunk_regenerate_credentials',
            relationships: { sms_trunk: { data: { type: 'sms_trunks', id: id } } }
          }
        }.to_json).
        to_return(
          status: 201,
          body: api_fixture('sms_trunk_regenerate_credentials/post/create/201'),
          headers: json_api_headers
        )
      expect(described_class.load(id: id).regenerate_credentials).to eq(true)
      expect(request).to have_been_made.once
    end
  end

  it_behaves_like 'a resource that PATCHes external_reference_id',
                  resource_type: 'sms_trunks',
                  path_prefix: 'sms_trunks',
                  id: '1a2b3c4d-0002-4a5b-8c6d-7e8f9a0b1c02'
end
