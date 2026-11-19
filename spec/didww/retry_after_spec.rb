# frozen_string_literal: true
RSpec.describe DIDWW::RetryAfter do
  describe '.seconds' do
    {
      '30' => 30,
      '0' => 0,
      '010' => 10,
      '0x10' => nil,
      '0b11' => nil,
      '1_0' => nil,
      '1.5' => nil,
      '-5' => nil,
      ' 5' => nil,
      "5\n" => nil,
      'Wed, 11 Nov 2026 07:28:00 GMT' => nil,
      '' => nil,
      nil => nil
    }.each do |value, seconds|
      it "reads #{value.inspect} as #{seconds.inspect}" do
        expect(described_class.seconds(value)).to eq(seconds)
      end
    end
  end
end
