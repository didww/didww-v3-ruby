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

    it '"expires_at", type: Time' do
      expect(encrypted_file.expires_at).to be_kind_of(Time)
    end
  end

  describe 'POST /encrypted_files (single file)' do
    let(:fingerprint) { 'aa:bb:cc' }
    let(:tempfile) { Tempfile.new(['passport', '.pdf']).tap { |f| f.write('PDF'); f.rewind } }
    let(:upload_file) do
      double('uploaded_file',
             tempfile: tempfile,
             content_type: 'application/pdf',
             original_filename: 'passport.pdf')
    end

    after { tempfile.close!; tempfile.unlink rescue nil }

    it 'POSTs a single file and returns the created resource id' do
      stub = stub_request(:post, "#{DIDWW::Client.api_base_url}encrypted_files")
        .to_return(
          status: 201,
          body: api_fixture('encrypted_files/post/create/201'),
          headers: json_api_headers
        )

      id = described_class.upload_file(upload_file, fingerprint)
      expect(id).to eq('f6a7b890-1234-5678-9abc-def123456789')
      expect(stub).to have_been_requested
    end

    it 'raises UploadError on non-201 response' do
      stub_request(:post, "#{DIDWW::Client.api_base_url}encrypted_files")
        .to_return(status: 422, body: '{"errors":[]}')

      expect {
        described_class.upload_file(upload_file, fingerprint)
      }.to raise_error(DIDWW::Resource::EncryptedFile::UploadError)
    end

    it 'no longer exposes upload_files batch helper' do
      expect(described_class).not_to respond_to(:upload_files)
    end
  end
end
