RSpec.describe DIDWW::Resource::CdrExport do
  let (:client) { DIDWW::Client }

  describe 'GET /cdr_exports/{id}' do
    let (:id) { '21e02b15-806d-44b3-b67f-434ea6c44f61' }

    context 'when CdrExport exists' do
      let (:cdr_export) do
        stub_didww_request(:get, "/cdr_exports/#{id}").to_return(
          status: 200,
          body: api_fixture('cdr_exports/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.cdr_exports.find(id).first
      end

      it 'returns a single CdrExport' do
        expect(cdr_export).to be_kind_of(DIDWW::Resource::CdrExport)
        expect(cdr_export.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"status", type: String' do
          expect(cdr_export.status).to be_in(['Pending', 'Processing', 'Completed'])
        end
        it '"url", type: String' do
          expect(cdr_export.url).to be_kind_of(String)
        end
        it '"created_at", type: Time' do
          expect(cdr_export.created_at).to be_kind_of(Time)
        end
        it '"filters", type: CdrExportFilter' do
          expect(cdr_export.filters).to be_kind_of(DIDWW::ComplexObject::CdrExportFilter)
        end
      end

      describe '#csv' do
        let (:csv_io) { cdr_export.csv }

        describe 'when file is ready' do
          before do
            stub_request(:get, cdr_export.url).to_return(
              status: 200,
              body: api_fixture('cdr_exports/id/get/sample_2/200', ext: :csv),
              headers: { 'Content-Type' => 'text/csv' }
            )
          end
          it 'does not raise an error' do
            expect { cdr_export.csv }.to_not raise_error
          end
          it 'returs a readable object' do
            expect(csv_io).to be_kind_of(Down::ChunkedIO)
            expect(csv_io.read).to be_kind_of(String)
          end
          it 'has csv caption' do
            expect(csv_io.read).to start_with('Date/Time (UTC),Source,DID,Destination')
          end
        end

        describe 'when url is empty' do
          before do
            cdr_export.url = nil
          end
          it 'does not call the api' do
            WebMock.reset!
            expect { cdr_export.csv }.to_not raise_error
            expect(a_request(:any, /.*/)).to_not have_been_made
          end
          it 'returs nil' do
            expect(csv_io).to be_nil
          end
        end

        describe 'when file is not found' do
          before do
            stub_request(:get, cdr_export.url).to_return(status: 404, body: '')
          end
          it 'raises a NotFound error' do
            expect { cdr_export.csv }.to raise_error(Down::ClientError)
          end
        end

      end
    end

    context 'when CdrExport does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/cdr_exports/#{id}").to_return(
          status: 404,
          body: api_fixture('cdr_exports/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.cdr_exports.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'GET /cdr_exports' do
    it 'returns a collection of CdrExports' do
      stub_didww_request(:get, '/cdr_exports').to_return(
        status: 200,
        body: api_fixture('cdr_exports/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.cdr_exports.all).to be_a_list_of(DIDWW::Resource::CdrExport)
    end
  end

  describe 'POST /cdr_exports' do
    describe 'with correct attributes' do
      before do
        stub_didww_request(:post, '/cdr_exports').
          with(body:
            {
              "data": {
                "type": 'cdr_exports',
                "attributes": {
                  "filters": {
                    "year": 2017,
                    "month": 5,
                    "did_number": '123456789'
                  }
                }
              }
            }.to_json).
          to_return(
            status: 201,
            body: api_fixture('cdr_exports/post/sample_1/201'),
            headers: json_api_headers
          )
      end
      it 'creates a CdrExport' do
        cdr_export = client.cdr_exports.create(year: 2017, month: 5, did_number: '123456789')
        expect(cdr_export).to be_persisted
      end
      it 'CdrExport has filters mapped after creation' do
        cdr_export = client.cdr_exports.create(year: 2017, month: 5, did_number: '123456789')
        expect(cdr_export.filters).to be_kind_of(DIDWW::ComplexObject::CdrExportFilter)
        expect(cdr_export.year).to eq(2017)
        expect(cdr_export.month).to eq(5)
        expect(cdr_export.did_number).to eq('123456789')
      end
    end
  end
end
