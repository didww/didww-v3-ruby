# frozen_string_literal: true
RSpec.describe DIDWW::Resource::VoiceOutTrunkRegenerateCredential do
  it 'has voice_out_trunk relationship' do
    resource = described_class.new
    expect(resource).to respond_to(:voice_out_trunk)
  end
end
