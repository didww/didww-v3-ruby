# frozen_string_literal: true
RSpec.describe DIDWW::Resource::EmergencyRequirement do
  let(:client) { DIDWW::Client }

  describe 'GET /emergency_requirements' do
    it 'returns a collection of EmergencyRequirement records' do
      stub_didww_request(:get, '/emergency_requirements').to_return(
        status: 200,
        body: api_fixture('emergency_requirements/get/without_includes/200'),
        headers: json_api_headers
      )
      records = client.emergency_requirements.all
      expect(records).to all be_an_instance_of(described_class)
      first = records.first
      expect(first.identity_type).to be_kind_of(String)
      expect(first.personal_area_level).to eq('country')
      expect(first.business_area_level).to be_nil
      expect(first.meta[:setup_price]).to eq('0.0')
      expect(first.address_mandatory_fields).to be_kind_of(Array)
      expect(first.personal_mandatory_fields).to be_kind_of(Array)
      expect(first.business_mandatory_fields).to be_kind_of(Array)
    end
  end

  describe 'GET /emergency_requirements/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'returns a single EmergencyRequirement record' do
      stub_didww_request(:get, "/emergency_requirements/#{id}").to_return(
        status: 200,
        body: api_fixture('emergency_requirements/id/get/without_includes/200'),
        headers: json_api_headers
      )
      record = client.emergency_requirements.find(id).first
      expect(record).to be_kind_of(described_class)
      expect(record.id).to eq(id)
      expect(record.estimate_setup_time).to be_kind_of(String)
      expect(record.personal_area_level).to be_nil
      expect(record.business_area_level).to eq('world_wide')
      expect(record.requirement_restriction_message).to be_kind_of(String).or be_nil
    end
  end
end
