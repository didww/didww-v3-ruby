# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Identity do
  let(:client) { DIDWW::Client }

  it 'has IDENTITY_TYPE constants' do
    expect(described_class::IDENTITY_TYPE_PERSONAL).to eq('Personal')
    expect(described_class::IDENTITY_TYPE_BUSINESS).to eq('Business')
    expect(described_class::IDENTITY_TYPE_ANY).to eq('Any')
  end

  describe 'GET /identities' do
    it 'returns a collection of Identities' do
      stub_didww_request(:get, '/identities').to_return(
        status: 200,
        body: api_fixture('identities/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.identities.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'has correct attributes' do
    let(:identity) do
      stub_didww_request(:get, '/identities').to_return(
        status: 200,
        body: api_fixture('identities/get/without_includes/200'),
        headers: json_api_headers
      )
      client.identities.all.first
    end

    it '"first_name", type: String' do
      expect(identity.first_name).to be_kind_of(String)
    end

    it '"last_name", type: String' do
      expect(identity.last_name).to be_kind_of(String)
    end

    it '"identity_type", type: String' do
      expect(identity.identity_type).to be_kind_of(String)
    end

    it '"created_at", type: Time' do
      expect(identity.created_at).to be_kind_of(Time)
    end

    it '"contact_email", type: String' do
      expect(identity.contact_email).to be_kind_of(String)
    end
  end

  describe 'type helper methods' do
    it '#personal?' do
      subject.identity_type = 'Personal'
      expect(subject).to be_personal
    end

    it '#business?' do
      subject.identity_type = 'Business'
      expect(subject).to be_business
    end
  end
end
