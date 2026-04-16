# frozen_string_literal: true
RSpec.describe DIDWW::Resource::EmergencyCallingService do
  let(:client) { DIDWW::Client }

  describe 'GET /emergency_calling_services' do
    it 'returns a collection of EmergencyCallingService records' do
      stub_didww_request(:get, '/emergency_calling_services').to_return(
        status: 200,
        body: api_fixture('emergency_calling_services/get/without_includes/200'),
        headers: json_api_headers
      )
      records = client.emergency_calling_services.all
      expect(records).to all be_an_instance_of(described_class)
      first = records.first
      expect(first.name).to be_kind_of(String)
      expect(first.status).to be_kind_of(String)
      expect(first.activated_at).to be_kind_of(Time).or be_nil
      expect(first.created_at).to be_kind_of(Time)
    end
  end

  describe 'GET /emergency_calling_services/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'returns a single EmergencyCallingService record' do
      stub_didww_request(:get, "/emergency_calling_services/#{id}").to_return(
        status: 200,
        body: api_fixture('emergency_calling_services/id/get/without_includes/200'),
        headers: json_api_headers
      )
      record = client.emergency_calling_services.find(id).first
      expect(record).to be_kind_of(described_class)
      expect(record.id).to eq(id)
      expect(record.reference).to be_kind_of(String).or be_nil
      expect(record.renew_date).to be_kind_of(Time).or be_nil
    end
  end

  describe 'associations' do
    it 'declares :address as a has_one so it shows up in associations and its setter dirty-tracks' do
      expect(described_class.associations.map(&:attr_name)).to include(:address)
    end
  end

  describe 'GET /emergency_calling_services/{id} with included address' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'sideloads the address relationship as Address' do
      stub_didww_request(:get, "/emergency_calling_services/#{id}?include=address").to_return(
        status: 200,
        body: api_fixture('emergency_calling_services/id/get/with_included_address/200'),
        headers: json_api_headers
      )
      record = client.emergency_calling_services.includes(:address).find(id).first
      expect(record.address).to be_kind_of(DIDWW::Resource::Address)
      expect(record.address.city_name).to eq('Berlin')
    end
  end

  describe 'DELETE /emergency_calling_services/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'cancels the emergency calling service' do
      stub_didww_request(:delete, "/emergency_calling_services/#{id}").to_return(
        status: 204,
        headers: json_api_headers
      )
      record = described_class.load(id: id).tap(&:mark_as_persisted!)
      expect(record.destroy).to eq(true)
    end
  end

  it 'exposes canonical STATUSES' do
    expect(described_class::STATUSES).to include('active', 'canceled', 'new')
  end
end
