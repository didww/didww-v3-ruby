# frozen_string_literal: true
RSpec.describe DIDWW::Resource::QtyBasedPricing do
  it 'has correct properties' do
    resource = described_class.new(
      qty: 10,
      setup_price: '2.00',
      monthly_price: '1.00'
    )
    expect(resource.qty).to be_kind_of(Integer)
    expect(resource.setup_price).to be_kind_of(BigDecimal)
    expect(resource.monthly_price).to be_kind_of(BigDecimal)
  end
end
