RSpec.describe DIDWW::Resource::DidReservation do
  let (:client) { DIDWW::Client }

  describe 'GET /did_reservations/:id' do
    subject do
      client.did_reservations.find(id)
    end

    let(:id) { 'dd13cdb2-48ab-4374-94b3-56e162a659cd' }
    let(:record) { subject.first }

    context 'when DID Reservation exists' do
      before do
        stub_didww_request(:get, "/did_reservations/#{id}").to_return(
            status: 200,
            body: api_fixture('did_reservations/id/get/sample_1/200'),
            headers: json_api_headers
        )
      end

      it 'returns correct object' do
        subject
        expect(record).to be_kind_of(DIDWW::Resource::DidReservation)
        expect(record.expire_at).to be_kind_of(Time)
        expect(record.created_at).to be_kind_of(Time)
      end
    end

    context 'when DID Reservation missing' do
      before do
        stub_didww_request(:get, "/did_reservations/#{id}").to_return(
            status: 404,
            body: api_fixture('did_reservations/id/get/sample_1/404'),
            headers: json_api_headers
        )
      end

      it 'raises 404' do
        expect { subject }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    context 'when include available_did' do
      subject do
        client.did_reservations.includes(:available_did).find(id)
      end

      before do
        stub_didww_request(:get, "/did_reservations/#{id}?include=available_did").to_return(
            status: 200,
            body: api_fixture('did_reservations/id/get/sample_2/200'),
            headers: json_api_headers
        )
      end

      it 'has available_did' do
        subject
        expect(record.available_did).to be_kind_of(DIDWW::Resource::AvailableDid)
      end
    end

    context 'when include available_did.did_group' do
      subject do
        client.did_reservations.includes(:'available_did.did_group').find(id)
      end

      before do
        stub_didww_request(:get, "/did_reservations/#{id}?include=available_did.did_group").to_return(
            status: 200,
            body: api_fixture('did_reservations/id/get/sample_3/200'),
            headers: json_api_headers
        )
      end

      it 'has did_group' do
        subject
        expect(record.available_did.did_group).to be_kind_of(DIDWW::Resource::DidGroup)
      end
    end

    context 'when include available_did.did_group.stock_keeping_units' do
      subject do
        client.did_reservations.includes(:'available_did.did_group.stock_keeping_units').find(id)
      end

      before do
        stub_didww_request(:get, "/did_reservations/#{id}?include=available_did.did_group.stock_keeping_units").
            to_return(
                status: 200,
                body: api_fixture('did_reservations/id/get/sample_4/200'),
                headers: json_api_headers
            )
      end

      it 'has stock_keeping_units' do
        subject
        expect(record.available_did.did_group.stock_keeping_units).to be_a_list_of(DIDWW::Resource::StockKeepingUnit)
      end
    end

  end

  describe 'GET /did_reservations' do
    subject do
      client.did_reservations.all
    end

    context 'when DID Reservations exists' do
      before do
        stub_didww_request(:get, '/did_reservations').to_return(
            status: 200,
            body: api_fixture('did_reservations/get/sample_1/200'),
            headers: json_api_headers
        )
      end

      it 'returns did_reservations' do
        expect(subject).to be_a_list_of(DIDWW::Resource::DidReservation)
      end
    end

      context 'when include available_did' do
      subject do
        client.did_reservations.includes(:available_did).all
      end

      before do
        stub_didww_request(:get, '/did_reservations?include=available_did').to_return(
            status: 200,
            body: api_fixture('did_reservations/get/sample_2/200'),
            headers: json_api_headers
        )
      end

      it 'returns did_group' do
        expect(subject.first.available_did).to be_kind_of(DIDWW::Resource::AvailableDid)
      end
      end

  end

  describe 'POST /did_reservations' do
    subject do
      instance = client.did_reservations.new(description: description)
      instance.relationships[:available_did] = DIDWW::Resource::AvailableDid.load(id: available_did_id)
      instance.save
      instance
    end

    let(:record) { subject.first }
    let(:available_did_id) { '8bc37f63-acd7-4e43-a760-1a1caa6e4683' }
    let(:description) { 'DIDWW' }
    let(:request_body) do
      {
          "data": {
              "type": 'did_reservations',
              "relationships": {
                  "available_did": {
                      "data": {
                          "type": 'available_dids',
                          "id": available_did_id
                      }
                  }
              },
              "attributes": {
                  "description": description
              }
          }
      }
    end

    context 'when did_reservation creates' do
      before do
        stub_didww_request(:post, '/did_reservations').
            with(body: request_body.to_json).
            to_return(
                status: 201,
                body: api_fixture('did_reservations/post/sample_1/201'),
                headers: json_api_headers
            )
      end

      it 'returns created did_reservation' do
        subject
        expect(subject.id).to be_kind_of(String)
        expect(subject).to be_persisted
      end
    end

    context 'when errors appears' do
      before do
        stub_didww_request(:post, '/did_reservations').
            with(body: request_body.to_json).
            to_return(
                status: 422,
                body: api_fixture('did_reservations/post/sample_1/422'),
                headers: json_api_headers
            )
      end

      it 'fills record errors' do
        subject
        expect(subject).to_not be_persisted
        expect(subject.errors.messages).to match(
                                               available_did: ['is invalid']
                                           )
      end
    end

  end

  describe 'DELETE /did_reservations/:id' do
    subject do
      client.did_reservations.load(id: id).destroy
    end

    let(:id) { '1156df17-bcea-4c9a-9c1d-29320e288c03' }

    before do
      stub_didww_request(:delete, "/did_reservations/#{id}").to_return(
          status: 204,
          headers: json_api_headers
      )
    end

    it 'deletes did_reservation' do
      subject
      expect(WebMock).to have_requested(:delete, api_uri("/did_reservations/#{id}"))
    end
  end

end
