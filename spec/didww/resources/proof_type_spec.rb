# frozen_string_literal: true
RSpec.describe DIDWW::Resource::ProofType do
  let(:client) { DIDWW::Client }

  describe 'GET /proof_types' do
    it 'returns a collection of ProofTypes' do
      stub_didww_request(:get, '/proof_types').to_return(
        status: 200,
        body: api_fixture('proof_types/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.proof_types.all).to all be_an_instance_of(described_class)
    end
  end
end
