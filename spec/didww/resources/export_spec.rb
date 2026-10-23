# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Export do
  let (:client) { DIDWW::Client }

  describe 'status constants and predicates' do
    it 'exposes STATUS_PENDING, STATUS_PROCESSING, STATUS_COMPLETED' do
      expect(described_class::STATUS_PENDING).to eq('pending')
      expect(described_class::STATUS_PROCESSING).to eq('processing')
      expect(described_class::STATUS_COMPLETED).to eq('completed')
    end

    it 'has EXPORT_TYPES covering CDR and SMS exports' do
      expect(described_class::EXPORT_TYPES).to eq(%w[cdr_in cdr_out sms_in sms_out])
    end

    it 'has STATUSES array covering all three values' do
      expect(described_class::STATUSES).to eq(%w[pending processing completed])
    end

    it 'exposes #pending? / #processing? / #completed? predicates' do
      export = described_class.new(status: 'pending')
      expect(export.pending?).to be true
      expect(export.processing?).to be false
      expect(export.completed?).to be false
      export.status = 'processing'
      expect(export.processing?).to be true
      export.status = 'completed'
      expect(export.completed?).to be true
    end
  end

  it_behaves_like 'a resource that PATCHes external_reference_id',
                  resource_type: 'exports',
                  path_prefix: 'exports',
                  new_value: 'renamed-ref-99'

  describe 'GET /exports/{id}' do
    let (:id) { '21e02b15-806d-44b3-b67f-434ea6c44f61' }

    context 'when Export exists' do
      let (:export) do
        stub_didww_request(:get, "/exports/#{id}").to_return(
          status: 200,
          body: api_fixture('exports/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.exports.find(id).first
      end

      it 'returns a single Export' do
        expect(export).to be_kind_of(DIDWW::Resource::Export)
        expect(export.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"status", type: String' do
          expect(export.status).to be_in(['pending', 'processing', 'completed'])
        end
        it '"url", type: String' do
          expect(export.url).to be_kind_of(String)
        end
        it '"created_at", type: Time' do
          expect(export.created_at).to be_kind_of(Time)
        end
        it '"external_reference_id", type: String' do
          expect(export.external_reference_id).to be_kind_of(String).or be_nil
        end
      end

      describe '#download' do
        let (:download_io) { export.download }
        let (:gzip_fixture) { File.binread(File.expand_path('../../fixtures/exports/id/get/csv_download/200.csv.gz', __dir__)) }

        describe 'when file is ready' do
          before do
            stub_request(:get, export.url).to_return(
              status: 200,
              body: gzip_fixture,
              headers: { 'Content-Type' => 'application/octet-stream' }
            )
          end
          it 'does not raise an error' do
            expect { export.download }.to_not raise_error
          end
          it 'returns a readable object' do
            expect(download_io).to be_kind_of(Tempfile)
            expect(download_io.read).to be_kind_of(String)
          end
          it 'returns the downloaded bytes unchanged' do
            expect(download_io.read).to eq(gzip_fixture)
          end
          it 'returns gzip data' do
            magic = download_io.read(2)
            expect(magic.bytes).to eq([0x1f, 0x8b])
          end
          it 'sends User-Agent header' do
            export.download
            expect(
              a_request(:get, export.url).with(headers: { 'User-Agent' => /didww-v3 Ruby gem v\d+\.\d+\.\d+/ })
            ).to have_been_made.once
          end
          it 'sends a bearer token and neither Api-Key nor X-DIDWW-API-Version' do
            export.download
            expect(
              a_request(:get, export.url).with(headers: { 'Authorization' => "Bearer #{StubRequestHelper::TEST_ACCESS_TOKEN}" }) { |req|
                (req.headers.keys.map(&:downcase) & ['api-key', 'x-didww-api-version']).empty?
              }
            ).to have_been_made.once
          end
        end

        describe 'when the token is refused' do
          before do
            url = export.url
            stub_request(:post, token_uri)
              .to_return(status: 200, body: token_body(access_token: 'second-token').to_json, headers: { 'Content-Type' => 'application/json' })
            stub_request(:get, url)
              .with(headers: { 'Authorization' => "Bearer #{StubRequestHelper::TEST_ACCESS_TOKEN}" })
              .to_return(status: 401, body: '{"errors":[{"title":"Unauthorized","status":"401"}]}', headers: json_api_headers)
            stub_request(:get, url)
              .with(headers: { 'Authorization' => 'Bearer second-token' })
              .to_return(status: 200, body: gzip_fixture, headers: { 'Content-Type' => 'application/octet-stream' })
          end
          it 'retries once with a new token and returns only the file bytes' do
            expect(download_io.read).to eq(gzip_fixture)
            expect(a_request(:get, export.url)).to have_been_made.twice
            expect(a_request(:post, token_uri)).to have_been_made.twice
          end
        end

        describe 'when url is empty' do
          before do
            export.url = nil
          end
          it 'does not call the api' do
            WebMock.reset!
            expect { export.download }.to_not raise_error
            expect(a_request(:any, /.*/)).to_not have_been_made
          end
          it 'returns nil' do
            expect(download_io).to be_nil
          end
        end

        describe 'when url is not on the API host' do
          {
            'another host' => 'https://files.example.com/exports/export.csv.gz',
            'http on the API host' => 'http://sandbox-api.didww.com/v3/exports/a4f6b765-f20c-45c7-98d2-80c2f3a41517.csv.gz',
            'http on the API host and port' => 'http://sandbox-api.didww.com:443/v3/exports/a4f6b765-f20c-45c7-98d2-80c2f3a41517.csv.gz',
            'another port on the API host' => 'https://sandbox-api.didww.com:8443/v3/exports/a4f6b765-f20c-45c7-98d2-80c2f3a41517.csv.gz'
          }.each do |name, foreign_url|
            it "raises ArgumentError for #{name} without minting a token or downloading" do
              export.url = foreign_url
              stub_request(:get, foreign_url).to_return(status: 200, body: gzip_fixture)
              DIDWW::Client.token_store = DIDWW::Auth::MemoryStore.new
              WebMock::RequestRegistry.instance.reset!

              expect { export.download }.to raise_error(ArgumentError, 'Export url must be on the API host https://sandbox-api.didww.com.')
              expect { export.csv }.to raise_error(ArgumentError)
              expect(a_request(:any, /.*/)).to_not have_been_made
            end
          end

          {
            'an unparsable url' => 'https://sandbox-api.didww.com/v3/exports/a b.csv.gz',
            'a url without a host' => 'https:/v3/exports/export.csv.gz'
          }.each do |name, malformed_url|
            it "raises ArgumentError for #{name} without minting a token" do
              export.url = malformed_url
              DIDWW::Client.token_store = DIDWW::Auth::MemoryStore.new
              WebMock::RequestRegistry.instance.reset!

              expect { export.download }.to raise_error(ArgumentError, 'Export url must be on the API host https://sandbox-api.didww.com.')
              expect(a_request(:any, /.*/)).to_not have_been_made
            end
          end

          it 'downloads a url on the API host written in another case, with a trailing dot and the default port' do
            export.url = 'https://SANDBOX-API.didww.com.:443/v3/exports/a4f6b765-f20c-45c7-98d2-80c2f3a41517.csv.gz'
            stub_request(:get, export.url).to_return(status: 200, body: gzip_fixture)

            expect(download_io.read).to eq(gzip_fixture)
          end
        end

        describe 'when DIDWW_API_URL points at another host' do
          before do
            export
            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:[]).with('DIDWW_API_URL').and_return('https://didww-proxy.example.com/v3/')
          end

          it 'downloads the url on the canonical API host of the mode' do
            stub_request(:get, export.url).to_return(status: 200, body: gzip_fixture)

            expect(download_io.read).to eq(gzip_fixture)
            expect(a_request(:get, export.url)).to have_been_made.once
          end

          it 'downloads a url on the DIDWW_API_URL host' do
            export.url = 'https://didww-proxy.example.com/v3/exports/a4f6b765-f20c-45c7-98d2-80c2f3a41517.csv.gz'
            stub_request(:get, export.url).to_return(status: 200, body: gzip_fixture)

            expect(download_io.read).to eq(gzip_fixture)
          end

          it 'raises ArgumentError for another host without a request' do
            export.url = 'https://files.example.com/exports/export.csv.gz'
            stub_request(:get, export.url).to_return(status: 200, body: gzip_fixture)
            WebMock::RequestRegistry.instance.reset!

            expect { export.download }.to raise_error(
              ArgumentError, 'Export url must be on the API host https://didww-proxy.example.com or https://sandbox-api.didww.com.'
            )
            expect(a_request(:any, /.*/)).to_not have_been_made
          end
        end

        describe 'when file is not found' do
          before do
            stub_request(:get, export.url).to_return(status: 404, body: '')
          end
          it 'raises a NotFound error' do
            expect { export.download }.to raise_error(JsonApiClient::Errors::NotFound)
          end
        end

        describe 'when the file is redirected' do
          before do
            stub_request(:get, export.url).to_return(status: 302, headers: { 'Location' => 'https://example.com/export.csv.gz' })
          end
          it 'raises UnexpectedStatus without following the redirect' do
            expect { export.download }.to raise_error(JsonApiClient::Errors::UnexpectedStatus)
            expect(a_request(:get, 'https://example.com/export.csv.gz')).to_not have_been_made
          end
          it 'removes the temp file' do
            tmp_path = nil
            allow(Tempfile).to receive(:new).and_wrap_original { |m, *args, **options| m.call(*args, **options).tap { |file| tmp_path = file.path } }

            expect { export.download }.to raise_error(JsonApiClient::Errors::UnexpectedStatus)
            expect(tmp_path).to be_a(String)
            expect(File.exist?(tmp_path)).to eq(false)
          end
        end

        describe 'when the answer has no content' do
          before do
            stub_request(:get, export.url).to_return(status: 204)
          end
          it 'raises UnexpectedStatus' do
            expect { export.download }.to raise_error(JsonApiClient::Errors::UnexpectedStatus)
          end
        end

      end
    end

    describe '#csv' do
      let (:export) do
        stub_didww_request(:get, "/exports/#{id}").to_return(
          status: 200,
          body: api_fixture('exports/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.exports.find(id).first
      end

      describe 'when file is ready' do
        before do
          stub_request(:get, export.url).to_return(
            status: 200,
            body: File.binread(File.expand_path('../../fixtures/exports/id/get/csv_download/200.csv.gz', __dir__)),
            headers: { 'Content-Type' => 'application/octet-stream' }
          )
        end
        it 'does not raise an error' do
          expect { export.csv }.to_not raise_error
        end
        it 'returns a StringIO' do
          expect(export.csv).to be_kind_of(StringIO)
        end
        it 'has csv caption' do
          expect(export.csv.read).to start_with('Date/Time Start (UTC)')
        end
        it 'removes the downloaded temp file' do
          downloaded_path = nil
          allow(export).to receive(:download).and_wrap_original { |m| m.call.tap { |file| downloaded_path = file.path } }

          export.csv

          expect(downloaded_path).to be_a(String)
          expect(File.exist?(downloaded_path)).to eq(false)
        end
      end

      describe 'when the file is not gzip' do
        before do
          stub_request(:get, export.url).to_return(status: 200, body: 'not gzip')
        end
        it 'removes the downloaded temp file' do
          downloaded_path = nil
          allow(export).to receive(:download).and_wrap_original { |m| m.call.tap { |file| downloaded_path = file.path } }

          expect { export.csv }.to raise_error(Zlib::GzipFile::Error)
          expect(downloaded_path).to be_a(String)
          expect(File.exist?(downloaded_path)).to eq(false)
        end
      end

      describe 'when url is empty' do
        before do
          export.url = nil
        end
        it 'returns nil' do
          expect(export.csv).to be_nil
        end
      end
    end

    context 'when Export does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/exports/#{id}").to_return(
          status: 404,
          body: api_fixture('exports/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.exports.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'GET /exports' do
    it 'returns a collection of Exports' do
      stub_didww_request(:get, '/exports').to_return(
        status: 200,
        body: api_fixture('exports/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.exports.all).to all be_an_instance_of(DIDWW::Resource::Export)
    end
  end

  describe 'POST /exports' do
    describe 'with correct attributes' do
      subject(:export) do
        client.exports.create(
          export_type: DIDWW::Resource::Export::EXPORT_TYPE_CDR_IN,
          filters: { from: '2026-04-01 00:00:00', to: '2026-04-15 23:59:59', did_number: '123456789' }
        )
      end

      before do
        stub_didww_request(:post, '/exports')
          .with(body: request_body.to_json)
          .to_return(
            status: 201,
            body: api_fixture('exports/post/create_success/201'),
            headers: json_api_headers
          )
      end

      let(:request_body) do
        {
          data: {
            type: 'exports',
            attributes: {
              filters: {
                from: '2026-04-01 00:00:00',
                to: '2026-04-15 23:59:59',
                did_number: '123456789'
              },
              export_type: DIDWW::Resource::Export::EXPORT_TYPE_CDR_IN
            }
          }
        }
      end

      it 'creates a Export' do
        expect(export).to be_persisted
      end
    end

    describe 'with an SMS export type' do
      subject(:export) do
        client.exports.create(
          export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_OUT,
          filters: {
            from: '2026-10-01 00:00:00',
            to: '2026-10-15 00:00:00',
            sms_trunk_id: sms_trunk_ids,
            service_type: 'a2p',
            sender_id_verification_id: sender_id_verification_id
          }
        )
      end

      let(:sms_trunk_ids) { %w[b2c3d4e5-0000-4000-8000-000000000001 b2c3d4e5-0000-4000-8000-000000000003] }
      let(:sender_id_verification_id) { 'c3d4e5f6-0000-4000-8000-000000000002' }
      let(:request_body) do
        {
          data: {
            type: 'exports',
            attributes: {
              filters: {
                from: '2026-10-01 00:00:00',
                to: '2026-10-15 00:00:00',
                service_type: 'a2p',
                'sms_trunk.id': sms_trunk_ids,
                'sender_id_verification.id': sender_id_verification_id
              },
              export_type: DIDWW::Resource::Export::EXPORT_TYPE_SMS_OUT
            }
          }
        }
      end

      before do
        stub_didww_request(:post, '/exports')
          .with(body: request_body.to_json)
          .to_return(
            status: 201,
            body: api_fixture('exports/post/create_sms_out/201'),
            headers: json_api_headers
          )
      end

      it 'creates an Export with the SMS filters under their wire keys' do
        expect(export).to be_persisted
        expect(export.export_type).to eq('sms_out')
        expect(export.filters.sms_trunk_id).to eq(sms_trunk_ids)
        expect(export.filters.sender_id_verification_id).to eq(sender_id_verification_id)
      end
    end
  end
end
