# frozen_string_literal: true
RSpec.describe DIDWW::Resource::DidGroup do
  let (:client) { DIDWW::Client }

  it 'does not define FEATURE_OUT_SMS' do
    expect(DIDWW::Resource::DidGroup).not_to be_const_defined(:FEATURE_OUT_SMS)
  end

  it 'exposes NUMBER_TYPES' do
    expect(described_class::NUMBER_TYPES).to eq(%w[local national mobile toll_free shared_cost global])
  end

  describe 'GET /did_groups/:id' do
    let (:id) { 'dd13cdb2-48ab-4374-94b3-56e162a659cd' }

    context 'when DidGroup exists' do
      let (:did_group) do
        stub_didww_request(:get, "/did_groups/#{id}").to_return(
          status: 200,
          body: api_fixture('did_groups/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.did_groups.find(id).first
      end

      it 'returns a single DidGroup' do
        expect(did_group).to be_kind_of(DIDWW::Resource::DidGroup)
        expect(did_group.id).to eq(id)
      end
      it 'the DidGroup has "area_name", type: String' do
        expect(did_group.area_name).to be_kind_of(String)
      end
      it 'the DidGroup has "prefix", type: String' do
        expect(did_group.prefix).to be_kind_of(String)
      end
      it 'the DidGroup has "is_metered", type: Boolean' do
        expect(did_group.is_metered).to be_in([true, false])
      end
      it 'the DidGroup has "allow_additional_channels", type: Boolean' do
        expect(did_group.allow_additional_channels).to be_in([true, false])
      end
      it 'the DidGroup has "service_restrictions", type: String' do
        expect(did_group.service_restrictions).to be_kind_of(String).or be_nil
      end
      it 'the DidGroup has "number_type", type: String' do
        expect(did_group.number_type).to eq(DIDWW::Resource::DidGroup::NUMBER_TYPE_LOCAL)
      end
      it 'the DidGroup has "is_demo", type: Boolean' do
        expect(did_group.is_demo).to eq(false)
      end
    end

    context 'when DidGroup does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/did_groups/#{id}").to_return(
          status: 404,
          body: api_fixture('did_groups/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.did_groups.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'has address_requirement relationship' do
      expect(described_class.new).to respond_to(:address_requirement)
    end

    it 'has no did_group_type relationship' do
      expect(described_class.associations.map(&:attr_name)).not_to include(:did_group_type)
    end

    it 'optionally includes Country, City, Region and a collection of StockKeepingUnits' do
      stub_didww_request(:get, "/did_groups/#{id}?include=country,city,region,stock_keeping_units").to_return(
        status: 200,
        body: api_fixture('did_groups/id/get/with_included_relationships/200'),
        headers: json_api_headers
      )
      did_group = client.did_groups.includes(:country, :city, :region, :stock_keeping_units).find(id).first
      expect(did_group.country).to be_kind_of(DIDWW::Resource::Country)
      expect(did_group.city).to be_kind_of(DIDWW::Resource::City).or be_nil
      expect(did_group.region).to be_kind_of(DIDWW::Resource::Region).or be_nil
      expect(did_group.number_type).to eq(DIDWW::Resource::DidGroup::NUMBER_TYPE_NATIONAL)
      expect(did_group.stock_keeping_units).to all be_an_instance_of(DIDWW::Resource::StockKeepingUnit)
    end
  end

  describe 'GET /did_groups' do
    it 'returns a collection of DidGroups' do
      stub_didww_request(:get, '/did_groups').to_return(
        status: 200,
        body: api_fixture('did_groups/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.did_groups.all).to all be_an_instance_of(DIDWW::Resource::DidGroup)
    end
    it 'optionally includes Countries' do
      stub_didww_request(:get, '/did_groups?include=country').to_return(
        status: 200,
        body: api_fixture('did_groups/get/with_included_relationships/200'),
        headers: json_api_headers
      )
      expect(client.did_groups.includes(:country).all.first.country).to be_kind_of(DIDWW::Resource::Country)
    end
  end

  describe 'GET /did_group?filter[nanpa_prefix.id]={id}' do
    context 'when DID group within NANPA prefix exists' do
      let(:nanpa_prefix_id) { SecureRandom.uuid }

      before do
        stub_didww_request(:get, "/did_groups?filter[nanpa_prefix.id]=#{nanpa_prefix_id}").to_return(
          status: 200,
          body: api_fixture('did_groups/get/without_includes/200'),
          headers: json_api_headers
        )
      end

      it 'returns a collection of DidGroups' do
        expect(client.did_groups.where('nanpa_prefix.id': nanpa_prefix_id).all).to all be_an_instance_of(DIDWW::Resource::DidGroup)
      end
    end
  end

  describe 'GET /did_group?filter[nanpa_prefix.npanxx]={npanxx}' do
    subject { client.did_groups.where('nanpa_prefix.npanxx': npa_nxx).all }

    let(:npa_nxx) { %w[864 920].join }

    context 'when DID group within 864920 NANPA prefix exists' do
      let!(:mock_get_record_request) do
        stub_didww_request(:get, "/did_groups?filter[nanpa_prefix.npanxx]=#{npa_nxx}").to_return(
          status: 200,
          body: api_fixture('did_groups/get/filter_by_npa_nxx/200'),
          headers: json_api_headers
        )
      end

      it 'returns a collection of DidGroups' do
        expect(subject).to all be_an_instance_of(DIDWW::Resource::DidGroup)
        expect(subject.count).to eq 1
        expect(subject.sample.type).to eq described_class.type
      end

      it 'request should be performed properly' do
        subject
        expect(mock_get_record_request).to have_been_requested.at_least_once
      end
    end
  end
end
