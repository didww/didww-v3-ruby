# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Proof do
  let(:client) { DIDWW::Client }

  describe 'GET /proofs' do
    it 'returns a collection of Proofs' do
      stub_didww_request(:get, '/proofs').to_return(
        status: 200,
        body: api_fixture('proofs/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.proofs.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'has correct attributes' do
    let(:proofs) do
      stub_didww_request(:get, '/proofs').to_return(
        status: 200,
        body: api_fixture('proofs/get/without_includes/200'),
        headers: json_api_headers
      )
      client.proofs.all
    end

    it '"expires_at" returns parsed date when present' do
      proof = proofs.first
      expect(proof.expires_at).to be_a(Time)
    end

    it '"expires_at" returns nil when null' do
      proof = proofs[1]
      expect(proof.expires_at).to be_nil
    end
  end
end
