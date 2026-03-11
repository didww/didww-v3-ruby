# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Export do
  let (:client) { DIDWW::Client }

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
          expect(export.status).to be_in(['Pending', 'Processing', 'Completed'])
        end
        it '"url", type: String' do
          expect(export.url).to be_kind_of(String)
        end
        it '"created_at", type: Time' do
          expect(export.created_at).to be_kind_of(Time)
        end
      end

      describe '#download' do
        let (:download_io) { export.download }

        describe 'when file is ready' do
          before do
            stub_request(:get, export.url).to_return(
              status: 200,
              body: File.binread(File.expand_path('../../fixtures/exports/id/get/csv_download/200.csv.gz', __dir__)),
              headers: { 'Content-Type' => 'application/octet-stream' }
            )
          end
          it 'does not raise an error' do
            expect { export.download }.to_not raise_error
          end
          it 'returns a readable object' do
            expect(download_io).to be_kind_of(Down::ChunkedIO)
            expect(download_io.read).to be_kind_of(String)
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

        describe 'when file is not found' do
          before do
            stub_request(:get, export.url).to_return(status: 404, body: '')
          end
          it 'raises a NotFound error' do
            expect { export.download }.to raise_error(Down::ClientError)
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
          filters: { year: 2017, month: 5, did_number: '123456789' }
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
                year: 2017,
                month: 5,
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
  end
end
