# frozen_string_literal: true
RSpec.describe DIDWW::Resource::StockKeepingUnit do
  it 'has correct properties' do
    resource = described_class.new(
      setup_price: '1.00',
      monthly_price: '0.50',
      channels_included_count: 2
    )
    expect(resource.setup_price).to be_kind_of(BigDecimal)
    expect(resource.monthly_price).to be_kind_of(BigDecimal)
    expect(resource.channels_included_count).to be_kind_of(Integer)
  end
end
