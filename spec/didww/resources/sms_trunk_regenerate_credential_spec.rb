# frozen_string_literal: true
RSpec.describe DIDWW::Resource::SmsTrunkRegenerateCredential do
  let(:sms_trunk_id) { '1a2b3c4d-0004-4a5b-8c6d-7e8f9a0b1c04' }
  let(:request_body) do
    {
      data: {
        type: 'sms_trunk_regenerate_credentials',
        relationships: { sms_trunk: { data: { type: 'sms_trunks', id: sms_trunk_id } } }
      }
    }.to_json
  end
  let(:resource) do
    described_class.new.tap do |r|
      r.relationships[:sms_trunk] = DIDWW::Resource::SmsTrunk.load(id: sms_trunk_id)
    end
  end

  it 'has sms_trunk relationship' do
    expect(described_class.new).to respond_to(:sms_trunk)
  end

  it 'serializes without an attributes member' do
    expect(resource.as_json_api).not_to have_key(:attributes)
  end

  describe 'POST /sms_trunk_regenerate_credentials' do
    it 'creates the resource' do
      stub_didww_request(:post, '/sms_trunk_regenerate_credentials').
        with(body: request_body).
        to_return(
          status: 201,
          body: api_fixture('sms_trunk_regenerate_credentials/post/create/201'),
          headers: json_api_headers
        )
      expect(resource.save).to eq(true)
      expect(resource.id).to eq('3c4d5e6f-0001-4c7d-8e9f-0a1b2c3d4e01')
    end

    context 'when the trunk has no credentials to rotate' do
      it 'returns errors' do
        stub_didww_request(:post, '/sms_trunk_regenerate_credentials').
          with(body: request_body).
          to_return(
            status: 422,
            body: api_fixture('sms_trunk_regenerate_credentials/post/create/422'),
            headers: json_api_headers
          )
        expect(resource.save).to eq(false)
        expect(resource.errors[:sms_trunk]).to contain_exactly('is invalid')
      end
    end
  end
end
