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

      it '"created_at", type: Time' do
        expect(trunk.created_at).to be_kind_of(Time)
      end
    end
  end
end
