# frozen_string_literal: true
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

    context 'with include nanpa_prefix' do
      subject do
        client.available_dids.includes(:nanpa_prefix).find(id)
      end

      let!(:mock_get_record_request) do
        stub_didww_request(:get, "/available_dids/#{id}?include=nanpa_prefix").to_return(
          status: 200,
          body: api_fixture('available_dids/get/include_nanpa_prefix/200'),
          headers: json_api_headers
        )
      end

      it 'should fetch NanpaPrefix resource' do
        subject
        expect(available_did.nanpa_prefix).to be_kind_of(DIDWW::Resource::NanpaPrefix)
        expect(available_did.nanpa_prefix).to have_attributes npa: be_kind_of(String), nxx: be_kind_of(String)
      end

      it 'request should be performed properly' do
        subject
        expect(mock_get_record_request).to have_been_requested.at_least_once
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
        expect(available_did.did_group.stock_keeping_units).to all be_an_instance_of(DIDWW::Resource::StockKeepingUnit)
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
        expect(subject).to all be_an_instance_of(described_class)
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

    describe 'GET /available_dids?filter[nanpa_prefix.id]={id}' do
      subject { client.available_dids.where('nanpa_prefix.id': nanpa_prefix_id).all }

      let(:nanpa_prefix_id) { SecureRandom.uuid }

      context 'when Available DID within NANPA prefix is exists' do
        let!(:mock_get_available_dids_request) do
          stub_didww_request(:get, "/available_dids?filter[nanpa_prefix.id]=#{nanpa_prefix_id}").to_return(
            status: 200,
            body: api_fixture('available_dids/get/sample_1/200'),
            headers: json_api_headers
          )
        end

        it 'returns a collection of Available Dids' do
          expect(subject).to all be_an_instance_of(described_class)
          expect(subject.count).to eq 2
          expect(subject.sample.type).to eq described_class.type
        end

        it 'request should be performed properly' do
          subject
          expect(mock_get_available_dids_request).to have_been_requested.at_least_once
        end
      end
    end
  end

end
