# frozen_string_literal: true
RSpec.describe DIDWW::Resource::RequirementValidation do
  it 'has requirement relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:requirement)
  end

  it 'has address relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:address)
  end

  it 'has identity relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:identity)
  end
end
