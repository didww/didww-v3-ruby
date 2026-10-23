# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Identity do
  let(:client) { DIDWW::Client }

  it 'has IDENTITY_TYPE constants' do
    expect(described_class::IDENTITY_TYPE_PERSONAL).to eq('personal')
    expect(described_class::IDENTITY_TYPE_BUSINESS).to eq('business')
    expect(described_class::IDENTITY_TYPE_ANY).to eq('any')
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

    it '"birth_date", type: String' do
      expect(identity.birth_date).to eq('1990-05-20')
    end

    it '"created_at", type: Time' do
      expect(identity.created_at).to be_kind_of(Time)
    end

    it '"contact_email", type: String' do
      expect(identity.contact_email).to be_kind_of(String)
    end

    it '"company_website", type: String' do
      expect(identity.company_website).to be_nil
    end
  end

  describe 'POST /identities' do
    it 'creates a business Identity with company_website' do
      stub_didww_request(:post, '/identities').
        with(body: json_api_post_body(
          type: 'identities',
          attributes: {
            identity_type: 'business',
            company_name: 'Acme Corp',
            company_website: 'https://example.com'
          }
        )).
        to_return(
          status: 201,
          body: api_fixture('identities/post/create_business/201'),
          headers: json_api_headers
        )
      identity = client.identities.new(
        identity_type: described_class::IDENTITY_TYPE_BUSINESS,
        company_name: 'Acme Corp',
        company_website: 'https://example.com'
      )
      identity.save
      expect(identity).to be_persisted
      expect(identity.company_website).to eq('https://example.com')
    end
  end

  describe 'PATCH /identities/:id' do
    let(:id) { '3b9b6c1a-4d2e-4f8a-9c7b-1e2d3f4a5b6c' }

    it 'updates company_website' do
      stub_didww_request(:patch, "/identities/#{id}").
        with(body: json_api_body(
          id: id,
          type: 'identities',
          attributes: { company_website: 'https://www.example.org' }
        )).
        to_return(
          status: 200,
          body: api_fixture('identities/id/patch/update_company_website/200'),
          headers: json_api_headers
        )
      identity = described_class.load(id: id)
      identity.company_website = 'https://www.example.org'
      expect(identity.save).to eq(true)
      expect(identity.company_website).to eq('https://www.example.org')
    end
  end

  describe 'birth_country relationship (2026-04-16)' do
    it 'has birth_country has_one relationship' do
      identity = described_class.new
      expect(identity).to respond_to(:birth_country)
    end
  end

  describe 'type helper methods' do
    it '#personal?' do
      subject.identity_type = 'personal'
      expect(subject).to be_personal
    end

    it '#business?' do
      subject.identity_type = 'business'
      expect(subject).to be_business
    end
  end
end
