# frozen_string_literal: true
#
# Shared examples for the two write-only "*RequirementValidation" resources
# (AddressRequirementValidation and EmergencyRequirementValidation). Each one
# posts an (address, identity, <requirement>) triple and the server returns
# 204 No Content when the combination is valid or JSONAPI errors when not.
#
# Callers must pass the class under test and the name of its requirement
# relationship:
#
#   it_behaves_like 'a requirement validation',
#     described_class,
#     requirement_relationship: :address_requirement,
#     client_accessor: :address_requirement_validation,
#     path: 'address_requirement_validations'
RSpec.shared_examples 'a requirement validation' do |resource_class, requirement_relationship:, client_accessor:, path:|
  it "has a :#{requirement_relationship} has_one" do
    expect(resource_class.new).to respond_to(requirement_relationship)
  end

  it 'has an :address has_one' do
    expect(resource_class.new).to respond_to(:address)
  end

  it 'has an :identity has_one' do
    expect(resource_class.new).to respond_to(:identity)
  end

  it "is exposed via client.#{client_accessor} accessor" do
    expect(DIDWW::Client.public_send(client_accessor)).to eq(resource_class)
  end

  it "maps to /#{path}" do
    expect(resource_class.path).to eq(path)
  end

  describe 'serialization' do
    it 'does not leak relationship objects into attributes' do
      validation = resource_class.new(
        relationships: {
          requirement_relationship => { data: { type: path, id: 'req-id' } },
          address: DIDWW::Resource::Address.load(id: 'addr-id'),
          identity: DIDWW::Resource::Identity.load(id: 'ident-id')
        }
      )
      body = validation.as_json_api

      expect(body).not_to have_key(:attributes)
      expect(body[:relationships]).to include(requirement_relationship, :address, :identity)
    end
  end

  describe 'POST with a valid combination' do
    let(:requirement_id) { '11111111-2222-3333-4444-555555555555' }
    let(:address_id)     { '66666666-7777-8888-9999-aaaaaaaaaaaa' }
    let(:identity_id)    { 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff' }

    let(:requirement_type) do
      requirement_class = resource_class.associations
                                        .find { |a| a.attr_name == requirement_relationship }
                                        .association_class
      requirement_class.path
    end

    it 'returns 204 No Content and leaves the record unpersisted' do
      stub_didww_request(:post, "/#{path}").with(
        body: {
          data: {
            type: path,
            relationships: {
              requirement_relationship => {
                data: { type: requirement_type, id: requirement_id }
              },
              address: { data: { type: 'addresses', id: address_id } },
              identity: { data: { type: 'identities', id: identity_id } }
            }
          }
        }.to_json
      ).to_return(status: 204, body: '', headers: json_api_headers)

      validation = resource_class.new(
        relationships: {
          requirement_relationship => { data: { type: requirement_type, id: requirement_id } },
          address: { data: { type: 'addresses', id: address_id } },
          identity: { data: { type: 'identities', id: identity_id } }
        }
      )

      expect(validation.save).to eq(true)
      expect(validation.errors).to be_empty
    end
  end
end
