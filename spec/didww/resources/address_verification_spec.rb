# frozen_string_literal: true
RSpec.describe DIDWW::Resource::AddressVerification do
  let(:client) { DIDWW::Client }

  it 'has STATUSES constant' do
    expect(described_class::STATUSES).to include('Pending', 'Approved', 'Rejected')
  end

  describe 'GET /address_verifications' do
    it 'returns a collection of AddressVerifications' do
      stub_didww_request(:get, '/address_verifications').to_return(
        status: 200,
        body: api_fixture('address_verifications/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.address_verifications.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'has correct attributes' do
    let(:verification) do
      stub_didww_request(:get, '/address_verifications').to_return(
        status: 200,
        body: api_fixture('address_verifications/get/without_includes/200'),
        headers: json_api_headers
      )
      client.address_verifications.all.first
    end

    it '"created_at", type: Time' do
      expect(verification.created_at).to be_kind_of(Time)
    end
  end

  describe 'status helper methods' do
    it '#pending?' do
      subject.status = 'Pending'
      expect(subject).to be_pending
    end

    it '#approved?' do
      subject.status = 'Approved'
      expect(subject).to be_approved
    end

    it '#rejected?' do
      subject.status = 'Rejected'
      expect(subject).to be_rejected
    end
  end
end
