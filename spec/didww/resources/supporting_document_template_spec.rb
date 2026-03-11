# frozen_string_literal: true
RSpec.describe DIDWW::Resource::SupportingDocumentTemplate do
  let(:client) { DIDWW::Client }

  describe 'GET /supporting_document_templates' do
    it 'returns a collection of SupportingDocumentTemplates' do
      stub_didww_request(:get, '/supporting_document_templates').to_return(
        status: 200,
        body: api_fixture('supporting_document_templates/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.supporting_document_templates.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'has correct attributes' do
    let(:template) do
      stub_didww_request(:get, '/supporting_document_templates').to_return(
        status: 200,
        body: api_fixture('supporting_document_templates/get/without_includes/200'),
        headers: json_api_headers
      )
      client.supporting_document_templates.all.first
    end

    it '"name", type: String' do
      expect(template.name).to be_kind_of(String)
    end

    it '"url", type: String' do
      expect(template.url).to be_kind_of(String)
    end

    it '"permanent", type: Boolean' do
      expect(template.permanent).to be_in([true, false])
    end
  end
end
