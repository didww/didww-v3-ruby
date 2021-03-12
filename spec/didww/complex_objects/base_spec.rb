# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::Base do
  class self::TestComplexObject < DIDWW::ComplexObject::Base
    property :known, type: :integer
  end

  describe 'any complex object' do
    let(:test_class)    { self.class::TestComplexObject }
    let(:test_instance) { test_class.new(known: '42', unknown: 'bar') }

    it 'can have arbitrary properties' do
      expect { test_instance }.not_to raise_error
      expect( test_instance[:unknown] ).to eq('bar')
    end

    it 'uses type casting for defined properties' do
      expect( test_instance.known ).to be_kind_of(Fixnum)
    end
  end
end
