# frozen_string_literal: true
RSpec.describe DIDWW::Resource::EncryptedFile do
  let(:client) { DIDWW::Client }

  describe 'GET /encrypted_files' do
    it 'returns a collection of EncryptedFiles' do
      stub_didww_request(:get, '/encrypted_files').to_return(
        status: 200,
        body: api_fixture('encrypted_files/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.encrypted_file.all).to all be_an_instance_of(described_class)
    end
  end

  describe 'has correct attributes' do
    let(:encrypted_file) do
      stub_didww_request(:get, '/encrypted_files').to_return(
        status: 200,
        body: api_fixture('encrypted_files/get/without_includes/200'),
        headers: json_api_headers
      )
      client.encrypted_file.all.first
    end

    it '"description", type: String' do
      expect(encrypted_file.description).to be_kind_of(String)
    end
  end
end
