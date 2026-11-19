# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::GenericOrderItem do
  it 'has JSONAPI type "generic_order_items"' do
    expect(described_class.type).to eq('generic_order_items')
  end

  describe 'returned properties' do
    it 'accepts qty, nrc, mrc, prorated_mrc, billed_from, billed_to' do
      item = described_class.new(
        qty: 1,
        nrc: '0.0',
        mrc: '5.0',
        prorated_mrc: false,
        billed_from: '2026-11-18',
        billed_to: '2026-12-17'
      )
      expect(item.qty).to eq(1)
      expect(item.nrc).to eq(BigDecimal('0.0'))
      expect(item.mrc).to eq(BigDecimal('5.0'))
      expect(item.prorated_mrc).to be(false)
      expect(item.billed_from).to eq('2026-11-18')
      expect(item.billed_to).to eq('2026-12-17')
    end
  end
end
