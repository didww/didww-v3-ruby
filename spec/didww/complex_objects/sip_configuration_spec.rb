# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::SipConfiguration do
  let (:sip_configuration) {
      DIDWW::ComplexObject::SipConfiguration.new.tap do |c|
        c.username = 'username'
        c.host = 'example.com'
        c.codec_ids = [ 9, 7 ]
        c.rx_dtmf_format_id = 1
        c.tx_dtmf_format_id = 2
        c.resolve_ruri = 'true'
        c.auth_enabled = true
        c.auth_user = 'username'
        c.auth_password = 'password'
        c.auth_from_user = 'Office'
        c.auth_from_domain = 'example.com'
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

end
