# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::ExportFilters do
  describe 'properties' do
    let(:property_names) do
      [].tap { |names| described_class.schema.each_property { |p| names << p.name } }
    end

    it 'declares from and to time-range properties' do
      expect(property_names).to include(:from, :to)
    end

    it 'no longer declares year/month/day properties' do
      expect(property_names).not_to include(:year, :month, :day)
    end

    it 'still declares did_number and voice_out_trunk_id' do
      expect(property_names).to include(:did_number, :voice_out_trunk_id)
    end
  end

  describe '#as_json' do
    it 'serialises from and to alongside the per-export filters' do
      filters = described_class.new(
        from: '2026-04-01 00:00:00',
        to: '2026-04-15 23:59:59',
        did_number: '123456789'
      )
      expect(filters.as_json).to include(
        'from' => '2026-04-01 00:00:00',
        'to' => '2026-04-15 23:59:59',
        'did_number' => '123456789'
      )
    end
  end
end
