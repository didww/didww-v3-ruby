# frozen_string_literal: true
RSpec.describe DIDWW::Resource::AddressRequirementValidation do
  it 'has address_requirement relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:address_requirement)
  end

  it 'has address relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:address)
  end

  it 'has identity relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:identity)
  end

  it 'is exposed via client.address_requirement_validation accessor' do
    expect(DIDWW::Client.address_requirement_validation).to eq(described_class)
  end

  it 'maps to /address_requirement_validations path' do
    expect(described_class.path).to eq('address_requirement_validations')
  end
end
