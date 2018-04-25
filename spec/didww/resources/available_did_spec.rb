RSpec.describe DIDWW::Resource::AvailableDid do
  let (:client) { DIDWW::Client }

  describe 'GET /available_dids/:id' do
    subject do
      client.available_dids.find(id)
    end

    let (:id) { 'dd13cdb2-48ab-4374-94b3-56e162a659cd' }
    let (:available_did) { subject.first }

    context 'when Available DID exists' do
      before do
        stub_didww_request(:get, "/available_dids/#{id}").to_return(
            status: 200,
            body: api_fixture('available_dids/id/get/sample_1/200'),
            headers: json_api_headers
        )
      end

      it 'returns a single Available DID' do
        subject
        expect(available_did).to be_kind_of(DIDWW::Resource::AvailableDid)
        expect(available_did.id).to eq(id)
        expect(available_did.number).to be_kind_of(String)
      end

    end

    context 'when Did does not exist' do
      before do
        stub_didww_request(:get, "/available_dids/#{id}").to_return(
            status: 404,
            body: api_fixture('available_dids/id/get/sample_1/404'),
            headers: json_api_headers
        )
      end

      it 'raises a NotFound error' do
        expect { subject }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    context 'with include did_group' do
      subject do
        client.available_dids.includes(:did_group).find(id)
      end

      before do
        stub_didww_request(:get, "/available_dids/#{id}?include=did_group").to_return(
            status: 200,
            body: api_fixture('dids/id/get/sample_2/200'),
            headers: json_api_headers
        )
      end

      it 'optionally includes DidGroup' do
        subject
        expect(available_did.did_group).to be_kind_of(DIDWW::Resource::DidGroup)
      end
    end

    context 'with include did_group.stock_keeping_units' do
      subject do
        client.available_dids.includes(:'did_group.stock_keeping_units').find(id)
      end

      before do
        stub_didww_request(:get, "/available_dids/#{id}?include=did_group.stock_keeping_units").to_return(
            status: 200,
            body: api_fixture('available_dids/id/get/sample_3/200'),
            headers: json_api_headers
        )
      end

      it 'optionally includes DidGroup' do
        subject
        expect(available_did.did_group.stock_keeping_units).to be_a_list_of(DIDWW::Resource::StockKeepingUnit)
      end
    end

  end

  describe 'GET /available_dids' do
    subject do
      client.available_dids.all
    end

    context 'when Available DIDs exists' do
      before do
        stub_didww_request(:get, '/available_dids').to_return(
            status: 200,
            body: api_fixture('dids/get/sample_1/200'),
            headers: json_api_headers
        )
      end

      it 'returns a collection of Dids' do
        expect(subject).to be_a_list_of(DIDWW::Resource::AvailableDid)
      end
    end

    context 'when include did_group' do
      subject do
        client.available_dids.includes(:did_group).all
      end

      before do
        stub_didww_request(:get, '/available_dids?include=did_group').to_return(
            status: 200,
            body: api_fixture('dids/get/sample_2/200'),
            headers: json_api_headers
        )
      end

      it 'optionally includes DidGroup' do
        expect(subject.first.did_group).to be_kind_of(DIDWW::Resource::DidGroup)
      end
    end

  end

end
