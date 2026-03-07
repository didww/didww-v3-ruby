# frozen_string_literal: true
RSpec.describe DIDWW::Resource::PermanentSupportingDocument do
  it 'has files relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:files)
  end

  it 'has template relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:template)
  end

  it 'has identity relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:identity)
  end
end
