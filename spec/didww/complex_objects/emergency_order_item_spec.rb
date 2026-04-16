# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::EmergencyOrderItem do
  it 'has JSONAPI type "emergency_order_items"' do
    expect(described_class.type).to eq('emergency_order_items')
  end

  describe 'input properties' do
    it 'accepts qty and emergency_calling_service_id' do
      item = described_class.new(
        qty: 1,
        emergency_calling_service_id: 'b6d9d793-578d-42d3-bc33-73dd8155e615'
      )
      expect(item.qty).to eq(1)
      expect(item.emergency_calling_service_id).to eq('b6d9d793-578d-42d3-bc33-73dd8155e615')
    end
  end

  describe 'returned properties' do
    it 'accepts nrc, mrc, prorated_mrc, billed_from, billed_to' do
      item = described_class.new(
        nrc: '5.0',
        mrc: '25.0',
        prorated_mrc: false,
        billed_from: '2026-04-16',
        billed_to: '2026-05-15'
      )
      expect(item.nrc).to eq(BigDecimal('5.0'))
      expect(item.mrc).to eq(BigDecimal('25.0'))
      expect(item.prorated_mrc).to be(false)
      expect(item.billed_from).to eq('2026-04-16')
      expect(item.billed_to).to eq('2026-05-15')
    end
  end

  describe '#as_json' do
    it 'serializes with type and attributes' do
      item = described_class.new(
        qty: 1,
        emergency_calling_service_id: 'b6d9d793-578d-42d3-bc33-73dd8155e615'
      )
      expect(item.as_json).to eq(
        'type' => 'emergency_order_items',
        'attributes' => {
          'qty' => 1,
          'emergency_calling_service_id' => 'b6d9d793-578d-42d3-bc33-73dd8155e615'
        }
      )
    end
  end
end
