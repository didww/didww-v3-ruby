# frozen_string_literal: true
RSpec.describe DIDWW::Resource::AddressVerification do
  let(:client) { DIDWW::Client }

  it 'has STATUSES constant' do
    expect(described_class::STATUSES).to include('pending', 'approved', 'rejected')
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

    it '"reference", type: String' do
      expect(verification.reference).to be_kind_of(String)
    end
  end

  describe 'GET /address_verifications/:id' do
    let(:id) { '429e6d4e-2ee9-4953-aa98-0b3ac07f0f96' }

    context 'when AddressVerification is rejected' do
      let(:address_verification) do
        stub_didww_request(:get, "/address_verifications/#{id}").to_return(
          status: 200,
          body: api_fixture('address_verifications/id/get/without_includes/200_rejected'),
          headers: json_api_headers
        )
        client.address_verifications.find(id).first
      end

      it 'returns a single AddressVerification' do
        expect(address_verification).to be_kind_of(described_class)
        expect(address_verification.id).to eq(id)
      end

      it 'has status "rejected"' do
        expect(address_verification.status).to eq('rejected')
      end

      it 'has reject_reasons' do
        expect(address_verification.reject_reasons).to eq(['Address cannot be validated', 'Proof of address should be not older than of 6 months'])
      end

      it 'has reference' do
        expect(address_verification.reference).to eq('ODW-879912')
      end

      it 'has reject_comment' do
        expect(address_verification.reject_comment).to eq('Please re-submit with a more recent utility bill.')
      end

      it 'has external_reference_id' do
        expect(address_verification.external_reference_id).to eq('crm-verif-0001')
      end
    end
  end

  describe 'PATCH /address_verifications/:id' do
    let(:id) { '429e6d4e-2ee9-4953-aa98-0b3ac07f0f96' }

    it 'updates external_reference_id' do
      stub_didww_request(:patch, "/address_verifications/#{id}").with(
        body: {
          data: {
            id: id,
            type: 'address_verifications',
            attributes: { external_reference_id: 'updated-ref-42' }
          }
        }.to_json
      ).to_return(
        status: 200,
        body: api_fixture('address_verifications/id/patch/update_external_reference_id/200'),
        headers: json_api_headers
      )
      verification = described_class.load(id: id)
      verification.external_reference_id = 'updated-ref-42'
      expect(verification.save).to eq(true)
      expect(verification.external_reference_id).to eq('updated-ref-42')
    end
  end

  describe 'status helper methods' do
    it '#pending?' do
      subject.status = 'pending'
      expect(subject).to be_pending
    end

    it '#approved?' do
      subject.status = 'approved'
      expect(subject).to be_approved
    end

    it '#rejected?' do
      subject.status = 'rejected'
      expect(subject).to be_rejected
    end
  end
end
