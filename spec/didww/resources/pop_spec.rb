# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Pop do
  let (:client) { DIDWW::Client }

  describe 'GET /pops' do
    it 'returns a collection of POPs' do
      stub_didww_request(:get, '/pops').to_return(
        status: 200,
        body: api_fixture('pops/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.pops.all).to all be_an_instance_of(DIDWW::Resource::Pop)
    end
  end

end
