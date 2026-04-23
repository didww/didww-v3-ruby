# frozen_string_literal: true
RSpec.describe DIDWW::Resource::DidHistory do
  let(:client) { DIDWW::Client }

  it 'uses the singular /did_history endpoint' do
    expect(described_class.table_name).to eq('did_history')
  end

  it 'has ACTIONS constant' do
    expect(described_class::ACTIONS).to contain_exactly(
      'assigned', 'renewed', 'canceled', 'removed', 'billing_cycles_count_changed', 'restored'
    )
  end

  it 'has METHODS constant' do
    expect(described_class::METHODS).to contain_exactly(
      'system', 'api2', 'api3', 'staff', 'user_panel'
    )
  end

  describe 'GET /did_history' do
    it 'returns a collection of DidHistory records' do
      stub_didww_request(:get, '/did_history').to_return(
        status: 200,
        body: api_fixture('did_history/get/without_includes/200'),
        headers: json_api_headers
      )
      records = client.did_history.all
      expect(records).to all be_an_instance_of(described_class)
      first = records.first
      expect(first.did_number).to be_kind_of(String)
      expect(first.action).to be_in(described_class::ACTIONS)
      expect(first.method).to be_in(described_class::METHODS)
      expect(first.created_at).to be_kind_of(Time)
    end
  end

  describe 'GET /did_history/{id}' do
    let(:id) { '01234567-89ab-cdef-0123-456789abcdef' }

    it 'returns a single DidHistory record' do
      stub_didww_request(:get, "/did_history/#{id}").to_return(
        status: 200,
        body: api_fixture('did_history/id/get/without_includes/200'),
        headers: json_api_headers
      )
      record = client.did_history.find(id).first
      expect(record).to be_kind_of(described_class)
      expect(record.id).to eq(id)
    end

    context 'when action is billing_cycles_count_changed' do
      let(:id) { 'c3d4e5f6-a7b8-9012-cdef-123456789012' }

      it 'exposes meta from/to fields' do
        stub_didww_request(:get, "/did_history/#{id}").to_return(
          status: 200,
          body: api_fixture('did_history/id/get/billing_cycles_count_changed/200'),
          headers: json_api_headers
        )
        record = client.did_history.find(id).first
        expect(record.action).to eq('billing_cycles_count_changed')
        expect(record.meta[:from]).to eq('2')
        expect(record.meta[:to]).to eq('1')
      end
    end
  end
end
