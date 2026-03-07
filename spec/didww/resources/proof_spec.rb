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
    let(:proof) do
      stub_didww_request(:get, '/proofs').to_return(
        status: 200,
        body: api_fixture('proofs/get/without_includes/200'),
        headers: json_api_headers
      )
      client.proofs.all.first
    end

    it '"is_expired", type: Boolean' do
      expect(proof.is_expired).to eq(false).or eq(true)
    end
  end
end
