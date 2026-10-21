# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::ExportFilters do
  describe 'properties' do
    let(:property_names) do
      [].tap { |names| described_class.schema.each_property { |p| names << p.name } }
    end

    it 'declares from and to time-range properties' do
      expect(property_names).to include(:from, :to)
    end

    it 'declares year/month/day as read-only properties' do
      expect(property_names).to include(:year, :month, :day)
      expect(described_class.read_only_attributes).to contain_exactly('year', 'month', 'day')
    end

    it 'still declares did_number and voice_out_trunk_id' do
      expect(property_names).to include(:did_number, :voice_out_trunk_id)
    end

    it 'declares the per-type CDR and SMS filters' do
      expect(property_names).to include(
        :source_number,
        :source_number_out,
        :source_country_iso,
        :source,
        :cli,
        :destination,
        :source_address_eq,
        :source_address_cont,
        :destination_address_eq,
        :destination_address_cont,
        :status,
        :trunk_type,
        :sms_trunk_id,
        :sms_id,
        :service_type,
        :sender_id_verification_id
      )
    end
  end

  it 'exposes TRUNK_TYPES' do
    expect(described_class::TRUNK_TYPES).to eq(['SMPP SMSC', 'SMPP ESME', 'Email', 'HTTP IN'])
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

    it 'sends sms_trunk_id and sender_id_verification_id under their dotted keys' do
      filters = described_class.new(
        sms_trunk_id: 'b2c3d4e5-0000-4000-8000-000000000001',
        sender_id_verification_id: 'c3d4e5f6-0000-4000-8000-000000000002'
      )
      expect(filters.as_json).to eq(
        'sms_trunk.id' => 'b2c3d4e5-0000-4000-8000-000000000001',
        'sender_id_verification.id' => 'c3d4e5f6-0000-4000-8000-000000000002'
      )
    end

    it 'passes array values through unchanged' do
      filters = described_class.new(
        sms_trunk_id: %w[b2c3d4e5-0000-4000-8000-000000000001 b2c3d4e5-0000-4000-8000-000000000003],
        trunk_type: [described_class::TRUNK_TYPE_EMAIL, described_class::TRUNK_TYPE_HTTP_IN]
      )
      expect(filters.as_json).to eq(
        'trunk_type' => ['Email', 'HTTP IN'],
        'sms_trunk.id' => %w[b2c3d4e5-0000-4000-8000-000000000001 b2c3d4e5-0000-4000-8000-000000000003]
      )
    end

    it 'does not send the read-only year/month/day' do
      filters = described_class.new(year: '2026', month: '4', from: '2026-04-01 00:00:00')
      expect(filters.as_json).to eq('from' => '2026-04-01 00:00:00')
    end
  end

  describe 'casting a server response' do
    it 'exposes dotted keys under their property names' do
      filters = described_class.cast(
        { 'from' => '2026-04-01 00:00:00', 'sms_trunk.id' => 'b2c3d4e5-0000-4000-8000-000000000001' },
        nil
      )
      expect(filters.sms_trunk_id).to eq('b2c3d4e5-0000-4000-8000-000000000001')
      expect(filters.as_json).to eq(
        'from' => '2026-04-01 00:00:00',
        'sms_trunk.id' => 'b2c3d4e5-0000-4000-8000-000000000001'
      )
    end
  end
end
