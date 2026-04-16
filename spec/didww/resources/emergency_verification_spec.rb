# frozen_string_literal: true
RSpec.describe DIDWW::Resource::EmergencyVerification do
  let(:client) { DIDWW::Client }

  describe 'GET /emergency_verifications' do
    it 'returns a collection of EmergencyVerification records' do
      stub_didww_request(:get, '/emergency_verifications').to_return(
        status: 200,
        body: api_fixture('emergency_verifications/get/without_includes/200'),
        headers: json_api_headers
      )
      records = client.emergency_verifications.all
      expect(records).to all be_an_instance_of(described_class)
      first = records.first
      expect(first.reference).to be_kind_of(String)
      expect(first.status).to eq('pending')
      expect(first.pending?).to eq(true)
      expect(first.approved?).to eq(false)
    end
  end

  describe 'GET /emergency_verifications/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'returns a single EmergencyVerification record' do
      stub_didww_request(:get, "/emergency_verifications/#{id}").to_return(
        status: 200,
        body: api_fixture('emergency_verifications/id/get/without_includes/200'),
        headers: json_api_headers
      )
      record = client.emergency_verifications.find(id).first
      expect(record).to be_kind_of(described_class)
      expect(record.id).to eq(id)
      expect(record.status).to eq('rejected')
      expect(record.rejected?).to eq(true)
      expect(record.reject_reasons).to be_kind_of(Array)
      expect(record.reject_comment).to be_kind_of(String)
      expect(record.external_reference_id).to be_kind_of(String).or be_nil
    end
  end

  describe 'POST /emergency_verifications' do
    it 'creates an EmergencyVerification with emergency_calling_service, address, and dids' do
      stub_didww_request(:post, '/emergency_verifications').with(
        body: {
          data: {
            type: 'emergency_verifications',
            relationships: {
              emergency_calling_service: {
                data: { type: 'emergency_calling_services', id: '33333333-4444-5555-6666-777777777777' }
              },
              address: {
                data: { type: 'addresses', id: '88888888-9999-aaaa-bbbb-cccccccccccc' }
              },
              dids: {
                data: [
                  { type: 'dids', id: '11111111-aaaa-bbbb-cccc-dddddddddddd' }
                ]
              }
            },
            attributes: {
              callback_url: 'https://example.com/emergency/hook',
              callback_method: 'POST',
              external_reference_id: 'ref-abc-123'
            }
          }
        }.to_json
      ).to_return(
        status: 201,
        body: api_fixture('emergency_verifications/post/create/201'),
        headers: json_api_headers
      )
      record = described_class.new(
        callback_url: 'https://example.com/emergency/hook',
        callback_method: 'POST',
        external_reference_id: 'ref-abc-123',
        relationships: {
          emergency_calling_service: { data: { type: 'emergency_calling_services', id: '33333333-4444-5555-6666-777777777777' } },
          address: { data: { type: 'addresses', id: '88888888-9999-aaaa-bbbb-cccccccccccc' } },
          dids: { data: [{ type: 'dids', id: '11111111-aaaa-bbbb-cccc-dddddddddddd' }] }
        }
      )
      expect(record.save).to eq(true)
      expect(record.persisted?).to eq(true)
      expect(record.status).to eq('pending')
    end
  end

  it 'exposes canonical STATUSES' do
    expect(described_class::STATUSES).to eq(%w[pending approved rejected])
  end
end
