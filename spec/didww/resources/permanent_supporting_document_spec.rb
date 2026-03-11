# frozen_string_literal: true
RSpec.describe DIDWW::Resource::PermanentSupportingDocument do
  let(:client) { DIDWW::Client }

  it 'has files relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:files)
  end

  it 'has template relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:template)
  end

  it 'has identity relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:identity)
  end

  describe 'has correct attributes' do
    let(:document) do
      stub_didww_request(:get, '/permanent_supporting_documents').to_return(
        status: 200,
        body: api_fixture('permanent_supporting_documents/get/without_includes/200'),
        headers: json_api_headers
      )
      client.permanent_supporting_documents.all.first
    end

    it '"created_at", type: Time' do
      expect(document.created_at).to be_kind_of(Time)
    end
  end
end
