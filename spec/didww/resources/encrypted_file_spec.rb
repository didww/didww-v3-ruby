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

    let(:upload_uri) { "#{DIDWW::Client.api_base_url}encrypted_files" }

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

    it 'raises an UploadError that is a DIDWW::Error' do
      stub_request(:post, upload_uri).to_return(status: 422, body: '{"errors":[]}')

      expect {
        described_class.upload_file(upload_file, fingerprint)
      }.to raise_error(DIDWW::Error)
    end

    it 'no longer exposes upload_files batch helper' do
      expect(described_class).not_to respond_to(:upload_files)
    end

    it 'sends a bearer token and no Api-Key header' do
      stub = stub_request(:post, upload_uri)
        .with(headers: { 'Authorization' => "Bearer #{StubRequestHelper::TEST_ACCESS_TOKEN}" }) { |req| !req.headers.key?('Api-Key') }
        .to_return(status: 201, body: api_fixture('encrypted_files/post/create/201'), headers: json_api_headers)

      described_class.upload_file(upload_file, fingerprint)

      expect(stub).to have_been_requested.once
    end

    context 'when the token is refused' do
      let(:sent_bodies) { [] }

      before do
        stub_request(:post, token_uri)
          .to_return(status: 200, body: token_body(access_token: 'first-token').to_json, headers: { 'Content-Type' => 'application/json' })
          .then.to_return(status: 200, body: token_body(access_token: 'second-token').to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, upload_uri)
          .with(headers: { 'Authorization' => 'Bearer first-token' })
          .to_return do |request|
            sent_bodies << request.body
            { status: 401, body: '' }
          end
        stub_request(:post, upload_uri)
          .with(headers: { 'Authorization' => 'Bearer second-token' })
          .to_return do |request|
            sent_bodies << request.body
            { status: 201, body: api_fixture('encrypted_files/post/create/201'), headers: json_api_headers }
          end
      end

      it 'rewinds the multipart body and retries once with a new token' do
        id = described_class.upload_file(upload_file, fingerprint)

        expect(id).to eq('f6a7b890-1234-5678-9abc-def123456789')
        expect(sent_bodies.size).to eq(2)
        expect(sent_bodies.first).to include('PDF')
        expect(sent_bodies.last).to eq(sent_bodies.first)
      end

      context 'when the file cannot be rewound' do
        let(:tempfile) do
          Tempfile.new(['passport', '.pdf']).tap do |file|
            file.write('PDF')
            file.rewind
            file.define_singleton_method(:rewind) { raise Errno::ESPIPE }
          end
        end

        it 'does not retry and raises UploadError' do
          expect {
            described_class.upload_file(upload_file, fingerprint)
          }.to raise_error(DIDWW::Resource::EncryptedFile::UploadError, /Code: 401/)
          expect(sent_bodies.size).to eq(1)
        end

        let(:rewindable_tempfile) { Tempfile.new(['passport', '.pdf']).tap { |f| f.write('PDF'); f.rewind } }
        let(:next_upload_file) do
          double('uploaded_file',
                 tempfile: rewindable_tempfile,
                 content_type: 'application/pdf',
                 original_filename: 'passport.pdf')
        end

        after { rewindable_tempfile.close! }

        it 'discards the refused token so the next upload mints a new one' do
          expect {
            described_class.upload_file(upload_file, fingerprint)
          }.to raise_error(DIDWW::Resource::EncryptedFile::UploadError)

          expect(described_class.upload_file(next_upload_file, fingerprint)).to eq('f6a7b890-1234-5678-9abc-def123456789')
          expect(a_request(:post, token_uri)).to have_been_made.twice
          expect(a_request(:post, upload_uri).with(headers: { 'Authorization' => 'Bearer first-token' })).to have_been_made.once
          expect(a_request(:post, upload_uri).with(headers: { 'Authorization' => 'Bearer second-token' })).to have_been_made.once
        end
      end
    end
  end
end
