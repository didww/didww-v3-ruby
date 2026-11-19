# frozen_string_literal: true
RSpec.describe DIDWW::Resource::SenderIdVerification do
  let(:client) { DIDWW::Client }
  let(:id) { 'e5a4e2f1-3b26-4a5c-9a0a-2f7c1f3e8d10' }
  let(:sms_trunk_id) { '1a2b3c4d-0003-4a5b-8c6d-7e8f9a0b1c03' }

  describe 'GET /sender_id_verifications' do
    let(:verifications) do
      stub_didww_request(:get, '/sender_id_verifications').to_return(
        status: 200,
        body: api_fixture('sender_id_verifications/get/without_includes/200'),
        headers: json_api_headers
      )
      client.sender_id_verifications.all
    end

    it 'returns a collection of SenderIdVerifications' do
      expect(verifications).to all be_an_instance_of(described_class)
      expect(verifications.size).to eq(2)
    end

    it 'reads the attributes of an active verification' do
      expect(verifications.first).to have_attributes(
        name: 'ACME alerts',
        status: described_class::STATUS_ACTIVE,
        sender_type: described_class::SENDER_TYPE_LONG_CODE,
        sender_ids: ['12125550100', '12125550101'],
        reference: 'SID-1234',
        reject_reasons: nil,
        reject_comment: nil,
        renew_date: '2026-11-22',
        created_at: Time.utc(2026, 10, 1, 10, 0, 0),
        activated_at: Time.utc(2026, 10, 3, 12, 30, 0),
        closed_at: nil
      )
    end

    it 'reads the rejection of a verification that requires changes' do
      expect(verifications.last).to have_attributes(
        status: described_class::STATUS_CHANGES_REQUIRED,
        sender_type: described_class::SENDER_TYPE_ALPHANUMERIC,
        reject_reasons: ['Company documents are missing'],
        reject_comment: 'Upload the certificate of incorporation.',
        renew_date: nil
      )
    end

    it 'reads the prices from meta' do
      expect(verifications.first.meta[:setup_price]).to eq('10.0')
      expect(verifications.first.meta[:monthly_price]).to eq('15.0')
    end

    it 'sends the server-side filters' do
      stub = stub_didww_request(:get, "/sender_id_verifications?filter[status]=active&filter[sms_trunk.id]=#{sms_trunk_id}").to_return(
        status: 200,
        body: api_fixture('sender_id_verifications/get/without_includes/200'),
        headers: json_api_headers
      )

      client.sender_id_verifications.where(status: described_class::STATUS_ACTIVE, 'sms_trunk.id': sms_trunk_id).all

      expect(stub).to have_been_requested.once
    end
  end

  describe 'GET /sender_id_verifications/{id}' do
    it 'optionally includes the SmsTrunk' do
      stub_didww_request(:get, "/sender_id_verifications/#{id}?include=sms_trunk").to_return(
        status: 200,
        body: api_fixture('sender_id_verifications/id/get/with_included_sms_trunk/200'),
        headers: json_api_headers
      )

      verification = client.sender_id_verifications.includes(:sms_trunk).find(id).first

      expect(verification.id).to eq(id)
      expect(verification.sms_trunk).to be_an_instance_of(DIDWW::Resource::SmsTrunk)
      expect(verification.sms_trunk.id).to eq(sms_trunk_id)
    end
  end

  describe 'PATCH /sender_id_verifications/{id}' do
    it 'renames the verification' do
      stub = stub_didww_request(:patch, "/sender_id_verifications/#{id}")
        .with(body: json_api_body(id: id, type: 'sender_id_verifications', attributes: { name: 'ACME notifications' }))
        .to_return(
          status: 200,
          body: api_fixture('sender_id_verifications/id/patch/update_name/200'),
          headers: json_api_headers
        )
      verification = described_class.load(id: id)
      verification.name = 'ACME notifications'

      expect(verification.save).to eq(true)
      expect(stub).to have_been_requested.once
      expect(verification.name).to eq('ACME notifications')
    end

    it 'assigns an SmsTrunk' do
      stub = stub_didww_request(:patch, "/sender_id_verifications/#{id}")
        .with(body: json_api_body(
          id: id,
          type: 'sender_id_verifications',
          relationships: { sms_trunk: { data: { type: 'sms_trunks', id: sms_trunk_id } } }
        ))
        .to_return(
          status: 200,
          body: api_fixture('sender_id_verifications/id/patch/assign_sms_trunk/200'),
          headers: json_api_headers
        )
      verification = described_class.load(id: id)
      verification.sms_trunk = DIDWW::Resource::SmsTrunk.load(id: sms_trunk_id)

      expect(verification.save).to eq(true)
      expect(stub).to have_been_requested.once
    end

    it 'unassigns the SmsTrunk' do
      stub = stub_didww_request(:patch, "/sender_id_verifications/#{id}")
        .with(body: json_api_body(id: id, type: 'sender_id_verifications', relationships: { sms_trunk: { data: nil } }))
        .to_return(
          status: 200,
          body: api_fixture('sender_id_verifications/id/patch/unassign_sms_trunk/200'),
          headers: json_api_headers
        )
      verification = described_class.load(id: id)
      verification.sms_trunk = nil

      expect(verification.save).to eq(true)
      expect(stub).to have_been_requested.once
    end

    context 'when the verification is closed' do
      it 'returns the verification with errors' do
        stub_didww_request(:patch, "/sender_id_verifications/#{id}").to_return(
          status: 422,
          body: api_fixture('sender_id_verifications/id/patch/closed/422'),
          headers: json_api_headers
        )
        verification = described_class.load(id: id)
        verification.name = 'Renamed'

        expect(verification.save).to eq(false)
        expect(verification.errors[:base]).to contain_exactly('Sender ID Verification is closed and can not be changed')
      end
    end
  end

  describe 'associations' do
    it 'declares the relationships of the document with their kind' do
      kinds = described_class.associations.to_h { |association| [association.attr_name, association.class] }

      expect(kinds).to eq(
        sms_trunk: JsonApiClient::Associations::HasOne::Association,
        countries: JsonApiClient::Associations::HasMany::Association,
        dids: JsonApiClient::Associations::HasMany::Association,
        order: JsonApiClient::Associations::HasOne::Association,
        identity: JsonApiClient::Associations::HasOne::Association,
        address: JsonApiClient::Associations::HasOne::Association
      )
    end
  end

  describe 'constants and predicates' do
    it 'lists every status' do
      expect(described_class::STATUSES).to eq(%w[active changes_required closed closing_in_process in_process new])
    end

    it 'lists every sender type' do
      expect(described_class::SENDER_TYPES).to eq(%w[alphanumeric carrier long_code short_code toll_free])
    end

    it 'exposes a predicate for every status' do
      verification = described_class.new(status: described_class::STATUS_ACTIVE)
      expect(verification.active?).to eq(true)
      expect(verification.closed?).to eq(false)
      verification.status = described_class::STATUS_CHANGES_REQUIRED
      expect(verification.changes_required?).to eq(true)
      verification.status = described_class::STATUS_CLOSED
      expect(verification.closed?).to eq(true)
      verification.status = described_class::STATUS_CLOSING_IN_PROCESS
      expect(verification.closing_in_process?).to eq(true)
      verification.status = described_class::STATUS_IN_PROCESS
      expect(verification.in_process?).to eq(true)
      verification.status = described_class::STATUS_NEW
      expect(verification.new_status?).to eq(true)
    end
  end
end
