# frozen_string_literal: true
require 'didww/complex_objects/configurations'

RSpec.describe DIDWW::ComplexObject::SipConfiguration do
  let(:example_host) { 'example.com' }
  let(:sip_reg_host) { 'sip.example.com' }
  let (:sip_configuration) {
      DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
        c.username = 'username'
        c.host = example_host
        c.codec_ids = [ 9, 7 ]
        c.rx_dtmf_format_id = 1
        c.tx_dtmf_format_id = 2
        c.resolve_ruri = 'true'
        c.auth_enabled = true
        c.auth_user = 'username'
        c.auth_password = 'password'
        c.auth_from_user = 'Office'
        c.auth_from_domain = example_host
        c.sst_enabled = 'false'
        c.sst_min_timer = 600
        c.sst_max_timer = 900
        c.sst_refresh_method_id = 3
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
      end
  }

  it 'has constants defined' do
    [
      'RX_DTMF_FORMATS',
      'TX_DTMF_FORMATS',
      'SST_REFRESH_METHODS',
      'REROUTING_DISCONNECT_CODES',
      'CODECS',
      'DEFAULT_REROUTING_DISCONNECT_CODE_IDS',
      'DEFAULT_CODEC_IDS',
      'TRANSPORT_PROTOCOLS',
      'DIVERSION_RELAY_POLICIES'
    ].each do |name|
      expect { described_class.const_get(name) }.to_not raise_error
    end
  end

  it 'exposes diversion_relay_policy (2026-04-16 replacement for diversion_relay_mode)' do
    sip = described_class.new
    sip.diversion_relay_policy = 'sip'
    expect(sip.diversion_relay_policy).to eq('sip')
    expect(described_class::DIVERSION_RELAY_POLICIES).to contain_exactly('none', 'as_is', 'sip', 'tel')
  end

  it 'has individual DIVERSION_RELAY_POLICY constants' do
    expect(described_class::DIVERSION_RELAY_POLICY_NONE).to eq('none')
    expect(described_class::DIVERSION_RELAY_POLICY_AS_IS).to eq('as_is')
    expect(described_class::DIVERSION_RELAY_POLICY_SIP).to eq('sip')
    expect(described_class::DIVERSION_RELAY_POLICY_TEL).to eq('tel')
    expect(described_class::DIVERSION_RELAY_POLICIES).to eq([
      described_class::DIVERSION_RELAY_POLICY_NONE,
      described_class::DIVERSION_RELAY_POLICY_AS_IS,
      described_class::DIVERSION_RELAY_POLICY_SIP,
      described_class::DIVERSION_RELAY_POLICY_TEL
    ])
  end

  describe '#rx_dtmf_format' do
    it 'returns humanized DTMF format' do
      expect(sip_configuration.rx_dtmf_format).to eq('RFC 2833')
    end
  end

  describe '#tx_dtmf_format' do
    it 'returns humanized DTMF format' do
      expect(sip_configuration.tx_dtmf_format).to eq('SIP INFO application/dtmf-relay')
    end
  end

  describe '#sst_refresh_method' do
    it 'returns humanized SST refresh method' do
      expect(sip_configuration.sst_refresh_method).to eq('Update fallback Invite')
    end
  end

  describe '#transport_protocol' do
    it 'returns humanized transport protocol' do
      expect(sip_configuration.transport_protocol).to eq('TCP')
    end
  end

  describe '2026-04-16 SIP registration attributes' do
    let(:configuration) do
      described_class.new(
        enabled_sip_registration: true,
        use_did_in_ruri: true,
        cnam_lookup: true,
        diversion_inject_mode: described_class::DIVERSION_INJECT_MODE_DID_NUMBER,
        network_protocol_priority: described_class::NETWORK_PROTOCOL_PRIORITY_PREFER_IPV4
      )
    end

    it 'exposes the values via reader methods' do
      expect(configuration.enabled_sip_registration).to be(true)
      expect(configuration.use_did_in_ruri).to be(true)
      expect(configuration.cnam_lookup).to be(true)
      expect(configuration.diversion_inject_mode).to eq('did_number')
      expect(configuration.network_protocol_priority).to eq('prefer_ipv4')
    end

    it 'serializes the writable attributes for PATCH/POST' do
      attrs = configuration.as_json[:attributes]
      expect(attrs).to include(
        'enabled_sip_registration' => true,
        'use_did_in_ruri' => true,
        'cnam_lookup' => true,
        'diversion_inject_mode' => 'did_number',
        'network_protocol_priority' => 'prefer_ipv4'
      )
    end

    it 'exposes valid enum constants' do
      expect(described_class::DIVERSION_INJECT_MODES).to contain_exactly('none', 'did_number')
      expect(described_class::NETWORK_PROTOCOL_PRIORITIES).to contain_exactly(
        'force_ipv4', 'force_ipv6', 'any', 'prefer_ipv4', 'prefer_ipv6'
      )
    end
  end

  describe 'incoming_auth credentials (read-only)' do
    let(:configuration) do
      described_class.new(
        host: example_host,
        incoming_auth_username: 'sipreg-user-1',
        incoming_auth_password: 's3cret'
      )
    end

    it 'exposes the values via reader methods' do
      expect(configuration.incoming_auth_username).to eq('sipreg-user-1')
      expect(configuration.incoming_auth_password).to eq('s3cret')
    end

    it 'omits read-only attributes from the JSON:API serialization' do
      payload = configuration.as_json
      expect(payload[:attributes]).to include('host' => example_host)
      expect(payload[:attributes]).not_to have_key('incoming_auth_username')
      expect(payload[:attributes]).not_to have_key('incoming_auth_password')
    end
  end

  describe 'auto-cascade for SIP registration (2026-04-16)' do
    # The SDK auto-cascades dependent fields whose constraints are
    # server-enforced: setting one field nullifies/forces another so user
    # code never has to track the full server-side rule set.

    it 'enabling SIP registration clears host and port' do
      cfg = described_class.new(host: sip_reg_host, port: 5060)
      cfg.enabled_sip_registration = true
      expect(cfg.host).to be_nil
      expect(cfg.port).to be_nil
      expect(cfg.enabled_sip_registration).to be(true)
    end

    it 'disabling SIP registration forces use_did_in_ruri to false' do
      cfg = described_class.new(enabled_sip_registration: true, use_did_in_ruri: true)
      cfg.enabled_sip_registration = false
      expect(cfg.enabled_sip_registration).to be(false)
      expect(cfg.use_did_in_ruri).to be(false)
    end

    it 'setting host disables SIP registration and forces use_did_in_ruri to false' do
      cfg = described_class.new(enabled_sip_registration: true, use_did_in_ruri: true)
      cfg.host = sip_reg_host
      expect(cfg.host).to eq(sip_reg_host)
      expect(cfg.enabled_sip_registration).to be(false)
      expect(cfg.use_did_in_ruri).to be(false)
    end

    it 'leaves use_did_in_ruri alone when SIP registration stays enabled' do
      cfg = described_class.new(enabled_sip_registration: true, use_did_in_ruri: true)
      cfg.enabled_sip_registration = true
      expect(cfg.use_did_in_ruri).to be(true)
    end

    it 'wire payload reflects the cascaded state' do
      cfg = described_class.new(enabled_sip_registration: true, use_did_in_ruri: true)
      cfg.host = sip_reg_host
      attrs = cfg.as_json[:attributes]
      expect(attrs['host']).to eq(sip_reg_host)
      expect(attrs['enabled_sip_registration']).to be(false)
      expect(attrs['use_did_in_ruri']).to be(false)
    end

    # Regression for 6.1.0: PATCH against an existing trunk that already has
    # a host on the server side. The local SipConfiguration starts empty, so
    # nothing is in the local attributes hash. Setting
    # `enabled_sip_registration = true` must still emit `host: null` /
    # `port: null` on the wire — otherwise the server merges the new field
    # with the persisted host and rejects with 422.
    it 'emits host=nil and port=nil even on a fresh config when enabling sip_registration' do
      cfg = described_class.new
      cfg.enabled_sip_registration = true
      attrs = cfg.as_json[:attributes]
      expect(attrs).to have_key('host')
      expect(attrs['host']).to be_nil
      expect(attrs).to have_key('port')
      expect(attrs['port']).to be_nil
      expect(attrs['enabled_sip_registration']).to be(true)
    end

    it 'constructor-time assignment bypasses the cascade so server responses deserialize as-is' do
      # Server may return a regular SIP trunk shape (host: present together
      # with use_did_in_ruri: true). The constructor uses []= directly,
      # which skips the cascading setters — running cascade against
      # already-consistent server data would clobber valid combinations.
      cfg = described_class.new(
        host: sip_reg_host, port: 5060,
        enabled_sip_registration: false, use_did_in_ruri: true
      )
      expect(cfg.host).to eq(sip_reg_host)
      expect(cfg.port).to eq(5060)
      expect(cfg.enabled_sip_registration).to be(false)
      expect(cfg.use_did_in_ruri).to be(true)
    end
  end

end
