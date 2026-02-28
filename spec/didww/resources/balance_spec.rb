# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Balance do
  let (:client) { DIDWW::Client }

  describe 'GET /balance' do
    let (:balance) do
      stub_didww_request(:get, '/balance').to_return(
        status: 200,
        body: api_fixture('balance/get/without_includes/200'),
        headers: json_api_headers
      )
      client.balance
    end

    it 'returns DIDWW::Resource::Balance' do
      expect(balance).to be_kind_of(DIDWW::Resource::Balance)
    end
    it 'the Balance has "balance", type: BigDecimal' do
      expect(balance.balance).to be_kind_of(BigDecimal)
    end
    it 'the Balance has "credit", type: BigDecimal' do
      expect(balance.credit).to be_kind_of(BigDecimal)
    end
    it 'the Balance has "total_balance", type: BigDecimal' do
      expect(balance.total_balance).to be_kind_of(BigDecimal)
    end
  end
end
