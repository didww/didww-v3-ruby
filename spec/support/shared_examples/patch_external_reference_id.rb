# frozen_string_literal: true
RSpec.shared_examples 'a resource that PATCHes external_reference_id' do |resource_type:, path_prefix:, id: '21e02b15-806d-44b3-b67f-434ea6c44f61', new_value: 'updated-ext-ref-99'|
  describe "PATCH /#{path_prefix}/:id" do
    it 'updates external_reference_id' do
      stub_didww_request(:patch, "/#{path_prefix}/#{id}").with(
        body: json_api_body(
          id: id,
          type: resource_type,
          attributes: { external_reference_id: new_value }
        )
      ).to_return(
        status: 200,
        body: api_fixture("#{path_prefix}/id/patch/update_external_reference_id/200"),
        headers: json_api_headers
      )
      record = described_class.load(id: id)
      record.external_reference_id = new_value
      expect(record.save).to eq(true)
      expect(record.external_reference_id).to be_kind_of(String)
    end
  end
end
