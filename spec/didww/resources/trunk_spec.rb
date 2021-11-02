# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Trunk do
  let (:client) { DIDWW::Client }

  it 'has CLI_FORMATS constant' do
    expect { described_class::CLI_FORMATS }.to_not raise_error
    expect(described_class::CLI_FORMATS).to include('e164', 'raw', 'local')
  end

  it 'has CONF_TYPES constant' do
    expect(described_class::CONF_TYPES).to include('sip_configurations', 'pstn_configurations').and have(4).items
    expect(described_class::CONF_TYPES.values).to include('SIP', 'PSTN')
    expect(described_class::CONF_TYPE_CLASSES.values).to all(be < DIDWW::ComplexObject::Base)
  end

  it 'can be initialized with given configuration type' do
    DIDWW::Resource::Trunk::CONF_TYPE_CLASSES.each do |type, klass|
      expect(described_class.new(configuration: { type: type }).configuration).to be_kind_of(klass)
    end
  end

  describe '#cli_format_human' do
    it 'humanizes cli_format attribute' do
      expect(subject.cli_format_human).to be_nil
      subject.cli_format = 'e164'
      expect(subject.cli_format_human).to eq('E.164')
    end
  end

  describe '#configuration_type_human' do
    it 'humanizes configuration type' do
      expect(subject.configuration_type_human).to be_nil
      subject.configuration = { type: 'iax2_configurations' }
      expect(subject.configuration_type_human).to eq('IAX2')
    end
  end

  describe 'GET /trunks/{id}' do
    let (:id) { 'df78e081-b7d1-4769-80ce-f349af4f612e' }

    context 'when Trunk exists' do
      let (:trunk) do
        stub_didww_request(:get, "/trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('trunks/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.trunks.find(id).first
      end

      it 'returns a single Trunk' do
        expect(trunk).to be_kind_of(DIDWW::Resource::Trunk)
        expect(trunk.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"priority", type: Integer' do
          expect(trunk.priority).to be_kind_of(Integer)
        end
        it '"weight", type: Integer' do
          expect(trunk.weight).to be_kind_of(Integer)
        end
        it '"capacity_limit", type: Integer' do
          expect(trunk.capacity_limit).to be_kind_of(Integer)
        end
        it '"ringing_timeout", type: Integer' do
          expect(trunk.ringing_timeout).to be_kind_of(Integer)
        end
        it '"name", type: String' do
          expect(trunk.name).to be_kind_of(String)
        end
        it '"cli_format", type: String' do
          expect(trunk.cli_format).to be_kind_of(String)
          expect(trunk.cli_format).to be_in(%w(raw e164 local))
        end
        it '"cli_prefix", type: String' do
          expect(trunk.cli_prefix).to be_kind_of(String)
        end
        it '"description", type: String' do
          expect(trunk.description).to be_kind_of(String).or be_nil
        end
        it '"created_at", type: Time' do
          expect(trunk.created_at).to be_kind_of(Time)
        end
      end

      it 'has TrunkGroup relationship' do
        expect(trunk.relationships[:trunk_group]).to be
      end

      it 'lazily fetches TrunkGroup' do
        request = stub_request(:get, trunk.relationships.trunk_group[:links][:related]).to_return(
            status: 200,
            body: api_fixture('trunk_groups/id/get/sample_1/200'),
            headers: json_api_headers
          )
        expect(trunk.trunk_group).to be_kind_of(DIDWW::Resource::TrunkGroup)
        expect(request).to have_been_made.once
      end
    end

    context 'when Trunk does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/trunks/#{id}").to_return(
          status: 404,
          body: api_fixture('trunks/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.trunks.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes TrunkGroup' do
      stub_didww_request(:get, "/trunks/#{id}?include=trunk_group").to_return(
        status: 200,
        body: api_fixture('trunks/id/get/sample_5/200'),
        headers: json_api_headers
      )
      trunk = client.trunks.includes(:trunk_group).find(id).first
      expect(trunk.trunk_group).to be_kind_of(DIDWW::Resource::TrunkGroup)
    end

    describe 'SIP trunk' do
      let (:id) { 'df78e081-b7d1-4769-80ce-f349af4f612e' }
      let (:trunk) do
        stub_didww_request(:get, "/trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('trunks/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.trunks.find(id).first
      end
      it 'has SipConfiguration' do
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::SipConfiguration)
      end
    end

    describe 'PSTN trunk' do
      let (:id) { '84746865-b1c0-414d-86c7-62c85c22fd69' }
      let (:trunk) do
        stub_didww_request(:get, "/trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('trunks/id/get/sample_2/200'),
          headers: json_api_headers
        )
        client.trunks.find(id).first
      end
      it 'has PstnConfiguration' do
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::PstnConfiguration)
      end
    end

    describe 'IAX2 trunk' do
      let (:id) { 'a393cbf8-a63c-42d4-8f64-93559f00fe38' }
      let (:trunk) do
        stub_didww_request(:get, "/trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('trunks/id/get/sample_3/200'),
          headers: json_api_headers
        )
        client.trunks.find(id).first
      end
      it 'has Iax2Configuration' do
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::Iax2Configuration)
      end
    end

    describe 'H323 trunk' do
      let (:id) { 'f9bf1d5c-bbd4-4739-9fd3-8ae162f2bc2b' }
      let (:trunk) do
        stub_didww_request(:get, "/trunks/#{id}").to_return(
          status: 200,
          body: api_fixture('trunks/id/get/sample_4/200'),
          headers: json_api_headers
        )
        client.trunks.find(id).first
      end
      it 'has H323Configuration' do
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::H323Configuration)
      end
    end
  end

  describe 'GET /trunks' do
    it 'returns a collection of Trunks' do
      stub_didww_request(:get, '/trunks').to_return(
        status: 200,
        body: api_fixture('trunks/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.trunks.all).to be_a_list_of(DIDWW::Resource::Trunk)
    end
  end

  describe 'POST /trunks' do
    describe 'with correct attributes' do
      it 'creates a SIP Trunk' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "attributes": {
                  "priority": 1,
                  "weight": 2,
                  "capacity_limit": 10,
                  "ringing_timeout": 30,
                  "name": 'Office',
                  "cli_format": 'e164',
                  "cli_prefix": '+',
                  "description": 'custom description',
                  "configuration": {
                    "type": 'sip_configurations',
                    "attributes": {
                      "username": 'username',
                      "host": 'example.com',
                      "codec_ids": [
                        9,
                        7
                      ],
                      "rx_dtmf_format_id": 1,
                      "tx_dtmf_format_id": 1,
                      "resolve_ruri": true,
                      "auth_enabled": true,
                      "auth_user": 'username',
                      "auth_password": 'password',
                      "auth_from_user": 'Office',
                      "auth_from_domain": 'example.com',
                      "sst_enabled": false,
                      "sst_min_timer": 600,
                      "sst_max_timer": 900,
                      "sst_refresh_method_id": 1,
                      "sst_accept_501": true,
                      "sip_timer_b": 8000,
                      "dns_srv_failover_timer": 2000,
                      "rtp_ping": false,
                      "rtp_timeout": 30,
                      "force_symmetric_rtp": false,
                      "symmetric_rtp_ignore_rtcp": false,
                      "rerouting_disconnect_code_ids": [
                        58,
                        59
                      ],
                      "port": 5060,
                      "transport_protocol_id": 2,
                      "max_transfers": 0,
                      "max_30x_redirects": 0
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunks/post/sample_1/201'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    priority: 1,
                    weight: 2,
                    capacity_limit: 10,
                    ringing_timeout: 30,
                    name: 'Office',
                    cli_format: 'e164',
                    cli_prefix: '+',
                    description: 'custom description'
                  )
        trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
          c.username = 'username'
          c.host = 'example.com'
          c.codec_ids = [ 9, 7 ]
          c.rx_dtmf_format_id = 1
          c.tx_dtmf_format_id = 1
          c.resolve_ruri = 'true'
          c.auth_enabled = true
          c.auth_user = 'username'
          c.auth_password = 'password'
          c.auth_from_user = 'Office'
          c.auth_from_domain = 'example.com'
          c.sst_enabled = 'false'
          c.sst_min_timer = 600
          c.sst_max_timer = 900
          c.sst_refresh_method_id = 1
          c.sst_accept_501 = 'true'
          c.sip_timer_b = 8000
          c.dns_srv_failover_timer = 2000
          c.rtp_ping = 'false'
          c.rtp_timeout = 30
          c.force_symmetric_rtp = 'false'
          c.symmetric_rtp_ignore_rtcp = 'false'
          c.rerouting_disconnect_code_ids = [ 58, 59 ]
          c.port = 5060
          c.transport_protocol_id = 2
          c.max_transfers = 0
          c.max_30x_redirects = 0
        end
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::SipConfiguration)
      end

      it 'creates a PSTN Trunk' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "attributes": {
                  "name": 'Office Mobile',
                  "capacity_limit": 5,
                  "configuration": {
                    "type": 'pstn_configurations',
                    "attributes": {
                      "dst": '1xxxxxxxxx'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunks/post/sample_2/201'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    name: 'Office Mobile',
                    capacity_limit: 5
                  )
        trunk.configuration = DIDWW::ComplexObject::PstnConfiguration.new.tap do |c|
          c.dst = '1xxxxxxxxx'
        end
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::PstnConfiguration)
      end

      it 'creates a IAX2 Trunk' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "attributes": {
                  "name": 'Office IAX2',
                  "capacity_limit": 9,
                  "cli_format": 'e164',
                  "cli_prefix": '+1',
                  "configuration": {
                    "type": 'iax2_configurations',
                    "attributes": {
                      "dst": '1xxxxxxxxx',
                      "host": 'example.com',
                      "auth_user": 'username',
                      "auth_password": 'password',
                      "codec_ids": [
                        9,
                        6
                      ]
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunks/post/sample_3/201'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    name: 'Office IAX2',
                    capacity_limit: 9,
                    cli_format: 'e164',
                    cli_prefix: '+1'
                  )
        trunk.configuration = DIDWW::ComplexObject::Iax2Configuration.new.tap do |c|
          c.dst = '1xxxxxxxxx'
          c.host = 'example.com'
          c.auth_user = 'username'
          c.auth_password = 'password'
          c.codec_ids = [ 9, 6 ]
        end
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::Iax2Configuration)
      end

      it 'creates a H323 Trunk' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "attributes": {
                  "name": 'Office H323',
                  "capacity_limit": 18,
                  "cli_format": 'e164',
                  "cli_prefix": '+1',
                  "configuration": {
                    "type": 'h323_configurations',
                    "attributes": {
                      "dst": '1xxxxxxxxx',
                      "host": 'example.com',
                      "codec_ids": [
                        9,
                        6
                      ]
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunks/post/sample_4/201'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    name: 'Office H323',
                    capacity_limit: 18,
                    cli_format: 'e164',
                    cli_prefix: '+1'
                  )
        trunk.configuration = DIDWW::ComplexObject::H323Configuration.new.tap do |c|
          c.dst = '1xxxxxxxxx'
          c.host = 'example.com'
          c.codec_ids = [ 9, 6 ]
        end
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::H323Configuration)
      end

      it 'creates a H323 Trunk with assign to trunk group' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "relationships": {
                  "trunk_group": {
                    "data": {
                      "type": 'trunk_groups',
                      "id": '86c9f271-0206-4906-833e-d4c09164468c'
                    }
                  }
                },
                "attributes": {
                  "name": 'Office H323',
                  "capacity_limit": 18,
                  "cli_format": 'e164',
                  "cli_prefix": '+1',
                  "configuration": {
                    "type": 'h323_configurations',
                    "attributes": {
                      "dst": '1xxxxxxxxx',
                      "host": 'example.com',
                      "codec_ids": [
                        9,
                        6
                      ]
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunks/post/sample_5/201'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    name: 'Office H323',
                    capacity_limit: 18,
                    cli_format: 'e164',
                    cli_prefix: '+1'
                  )
        trunk.configuration = DIDWW::ComplexObject::H323Configuration.new.tap do |c|
          c.dst = '1xxxxxxxxx'
          c.host = 'example.com'
          c.codec_ids = [ 9, 6 ]
        end
        trunk.relationships[:trunk_group] = DIDWW::Resource::TrunkGroup.load(id: '86c9f271-0206-4906-833e-d4c09164468c')
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::H323Configuration)
        expect(trunk.trunk_group).to be_kind_of(DIDWW::Resource::TrunkGroup)
      end

      xit 'creates a H323 Trunk, assign it to trunk group and include it in response'

      it 'creates a SIP trunk with assigning to pop' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "relationships": {
                  "pop": {
                    "data": {
                      "type": 'pops',
                      "id": '240416e4-aeb2-4ca5-9df2-f37f01e930cf'
                    }
                  }
                },
                "attributes": {
                  "name": 'Office SIP',
                  "capacity_limit": 18,
                  "cli_format": 'e164',
                  "cli_prefix": '+1',
                  "configuration": {
                    "type": 'sip_configurations',
                    "attributes": {
                      "username": 'username',
                      "host": 'example.com',
                      "codec_ids": [
                        9,
                        7
                      ],
                      "rx_dtmf_format_id": 1,
                      "tx_dtmf_format_id": 1,
                      "resolve_ruri": true,
                      "auth_enabled": true,
                      "auth_user": 'username',
                      "auth_password": 'password',
                      "auth_from_user": 'Office',
                      "auth_from_domain": 'example.com',
                      "sst_enabled": false,
                      "sst_min_timer": 600,
                      "sst_max_timer": 900,
                      "sst_refresh_method_id": 1,
                      "sst_accept_501": true,
                      "sip_timer_b": 8000,
                      "dns_srv_failover_timer": 2000,
                      "rtp_ping": false,
                      "rtp_timeout": 30,
                      "force_symmetric_rtp": false,
                      "symmetric_rtp_ignore_rtcp": false,
                      "rerouting_disconnect_code_ids": [
                        58,
                        59
                      ],
                      "port": 5060,
                      "transport_protocol_id": 2,
                      "max_transfers": 0,
                      "max_30x_redirects": 0
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('trunks/post/sample_6/201'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    name: 'Office SIP',
                    capacity_limit: 18,
                    cli_format: 'e164',
                    cli_prefix: '+1',
                  )
        trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
          c.username = 'username'
          c.host = 'example.com'
          c.codec_ids = [ 9, 7 ]
          c.rx_dtmf_format_id = 1
          c.tx_dtmf_format_id = 1
          c.resolve_ruri = 'true'
          c.auth_enabled = true
          c.auth_user = 'username'
          c.auth_password = 'password'
          c.auth_from_user = 'Office'
          c.auth_from_domain = 'example.com'
          c.sst_enabled = 'false'
          c.sst_min_timer = 600
          c.sst_max_timer = 900
          c.sst_refresh_method_id = 1
          c.sst_accept_501 = 'true'
          c.sip_timer_b = 8000
          c.dns_srv_failover_timer = 2000
          c.rtp_ping = 'false'
          c.rtp_timeout = 30
          c.force_symmetric_rtp = 'false'
          c.symmetric_rtp_ignore_rtcp = 'false'
          c.rerouting_disconnect_code_ids = [ 58, 59 ]
          c.port = 5060
          c.transport_protocol_id = 2
          c.max_transfers = 0
          c.max_30x_redirects = 0
        end
        trunk.relationships[:pop] = DIDWW::Resource::Pop.load(id: '240416e4-aeb2-4ca5-9df2-f37f01e930cf')
        trunk.save
        expect(trunk).to be_persisted
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::SipConfiguration)
        expect(trunk.pop).to be_kind_of(DIDWW::Resource::Pop)
      end

      xit 'creates a SIP trunk with assigning to pop and including it to response'

    end

    describe 'with incorerct attributes' do
      it 'returns an Trunk with errors' do
        stub_didww_request(:post, '/trunks').
          with(body:
            {
              "data": {
                "type": 'trunks',
                "attributes": {
                  "name": 'Office Mobile',
                  "capacity_limit": 5,
                  "configuration": {
                    "type": 'pstn_configurations',
                    "attributes": {
                      "dst": '1xxxxxxxxx'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('trunks/post/sample_1/422'),
            headers: json_api_headers
          )
        trunk = client.trunks.new(
                    name: 'Office Mobile',
                    capacity_limit: 5
                  )
        trunk.configuration = DIDWW::ComplexObject::PstnConfiguration.new.tap do |c|
          c.dst = '1xxxxxxxxx'
        end
        trunk.save
        expect(trunk).not_to be_persisted
        expect(trunk.errors).to have_at_least(1).item
      end
    end
  end

  describe 'PATCH /trunks/{id}' do
    describe 'with correct attributes' do
      it 'updates a SIP Trunk' do
        id = '57a939dd-1600-41a6-80b1-f624e22a1f4c'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '57a939dd-1600-41a6-80b1-f624e22a1f4c',
                "type": 'trunks',
                "attributes": {
                  "configuration": {
                    "type": 'sip_configurations',
                    "attributes": {
                      "username": 'new_username'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunks/id/patch/sample_1/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |config|
          config.username = 'new_username'
        end
        trunk.save
        expect(trunk.errors).to be_empty
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::SipConfiguration)
        expect(trunk.configuration.username).to eq('new_username')
      end

      it 'updates a PSTN Trunk' do
        id = '989d8259-9c4f-4449-97b7-a3480b1cffff'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '989d8259-9c4f-4449-97b7-a3480b1cffff',
                "type": 'trunks',
                "attributes": {
                  "configuration": {
                    "type": 'pstn_configurations',
                    "attributes": {
                      "dst": '7xxxxxxxx'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunks/id/patch/sample_2/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.configuration = DIDWW::ComplexObject::PstnConfiguration.new.tap do |config|
          config.dst = '7xxxxxxxx'
        end
        trunk.save
        expect(trunk.errors).to be_empty
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::PstnConfiguration)
        expect(trunk.configuration.dst).to eq('7xxxxxxxx')
      end

      it 'updates a IAX2 Trunk' do
        id = '86c9f271-0206-4906-833e-d4c09164468c'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '86c9f271-0206-4906-833e-d4c09164468c',
                "type": 'trunks',
                "attributes": {
                  "configuration": {
                    "type": 'iax2_configurations',
                    "attributes": {
                      "dst": '7xxxxxxxx'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunks/id/patch/sample_3/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.configuration = DIDWW::ComplexObject::Iax2Configuration.new.tap do |config|
          config.dst = '7xxxxxxxx'
        end
        trunk.save
        expect(trunk.errors).to be_empty
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::Iax2Configuration)
        expect(trunk.configuration.dst).to eq('7xxxxxxxx')
      end

      it 'updates a H323 Trunk' do
        id = '389deacb-5be5-46d7-8cbd-aba11f66d6c2'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '389deacb-5be5-46d7-8cbd-aba11f66d6c2',
                "type": 'trunks',
                "attributes": {
                  "configuration": {
                    "type": 'h323_configurations',
                    "attributes": {
                      "dst": '7xxxxxxxx'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunks/id/patch/sample_4/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.configuration = DIDWW::ComplexObject::H323Configuration.new.tap do |config|
          config.dst = '7xxxxxxxx'
        end
        trunk.save
        expect(trunk.errors).to be_empty
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::H323Configuration)
        expect(trunk.configuration.dst).to eq('7xxxxxxxx')
      end

      it 'updates a H323 Trunk with assign to trunk group' do
        id = '389deacb-5be5-46d7-8cbd-aba11f66d6c2'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '389deacb-5be5-46d7-8cbd-aba11f66d6c2',
                "type": 'trunks',
                "relationships": {
                  "trunk_group": {
                    "data": {
                      "type": 'trunk_groups',
                      "id": '86c9f271-0206-4906-833e-d4c09164468c'
                    }
                  }
                },
                "attributes": {
                  "configuration": {
                    "type": 'h323_configurations',
                    "attributes": {
                      "dst": '7xxxxxxxx'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunks/id/patch/sample_5/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.configuration = DIDWW::ComplexObject::H323Configuration.new.tap do |config|
          config.dst = '7xxxxxxxx'
        end
        trunk.relationships[:trunk_group] = DIDWW::Resource::TrunkGroup.load(id: '86c9f271-0206-4906-833e-d4c09164468c')
        trunk.save
        expect(trunk.errors).to be_empty
        expect(trunk.configuration).to be_kind_of(DIDWW::ComplexObject::H323Configuration)
        expect(trunk.configuration.dst).to eq('7xxxxxxxx')
        expect(trunk.trunk_group).to be_kind_of(DIDWW::Resource::TrunkGroup)
      end

      xit 'updates a H323 Trunk, assign it to trunk group and include it in response'

      it 'updates a SIP Trunk with assigning to pop' do
        id = '081ad751-d790-4e70-9c92-7c18f6b50a6d'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '081ad751-d790-4e70-9c92-7c18f6b50a6d',
                "type": 'trunks',
                "relationships": {
                  "pop": {
                    "data": {
                      "type": 'pops',
                      "id": 'cb5ea690-e3a3-4781-a4f3-3bd0123284dd'
                    }
                  }
                },
                "attributes": {
                  "name": 'New trunk'
                }
              }
            }.to_json).
          to_return(
            status: 200,
            body: api_fixture('trunks/id/patch/sample_6/200'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.name = 'New trunk'
        trunk.relationships.pop = DIDWW::Resource::Pop.load(id: 'cb5ea690-e3a3-4781-a4f3-3bd0123284dd')
        trunk.save
        expect(trunk.errors).to be_empty
        expect(trunk.name).to eq('New trunk')
        expect(trunk.pop).to be_kind_of(DIDWW::Resource::Pop)
      end

      xit 'updates a SIP Trunk, with assigning to pop and including it to response'

    end

    describe 'with incorerct attributes' do
      it 'returns a Trunk with errors' do
        id = '57a939dd-1600-41a6-80b1-f624e22a1f4c'
        stub_didww_request(:patch, "/trunks/#{id}").
          with(body:
            {
              "data": {
                "id": '57a939dd-1600-41a6-80b1-f624e22a1f4c',
                "type": 'trunks',
                "attributes": {
                  "configuration": {
                    "type": 'sip_configurations',
                    "attributes": {
                      "username": 'new_username'
                    }
                  }
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('trunks/id/patch/sample_1/422'),
            headers: json_api_headers
          )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        trunk.configuration = DIDWW::ComplexObject::SipConfiguration.new.tap do |config|
          config.username = 'new_username'
        end
        trunk.save
        expect(trunk.errors).to have_at_least(1).item
      end
    end
  end

  describe 'DELETE /trunks/{id}' do
    let (:id) { 'c3947e93-4a3b-4080-b9d3-cbcc633ab808s' }
    it 'deletes a Trunk' do
      stub_didww_request(:delete, "/trunks/#{id}").
        to_return(
          status: 202,
          body: api_fixture('trunks/id/delete/sample_1/202'),
          headers: json_api_headers
        )
      trunk = DIDWW::Resource::Trunk.load(id: id)
      expect(trunk.destroy)
      expect(WebMock).to have_requested(:delete, api_uri("/trunks/#{id}"))
    end

    context 'when Trunk does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:delete, "/trunks/#{id}").
        to_return(
          status: 404,
          body: api_fixture('trunks/id/delete/sample_1/404'),
          headers: json_api_headers
        )
        trunk = DIDWW::Resource::Trunk.load(id: id)
        expect { trunk.destroy }.to raise_error(JsonApiClient::Errors::NotFound)
        expect(WebMock).to have_requested(:delete, api_uri("/trunks/#{id}"))
      end
    end
  end

end
