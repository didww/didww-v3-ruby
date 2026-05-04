# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::Base do
  class self::TestComplexObject < DIDWW::ComplexObject::Base
    property :known, type: :integer
  end

  class self::TestSecretObject < DIDWW::ComplexObject::Base
    property :username, type: :string
    property :password, type: :string, sensitive: true
    property :api_key,  type: :string, sensitive: true
  end

  describe 'any complex object' do
    let(:test_class)    { self.class::TestComplexObject }
    let(:test_instance) { test_class.new(known: '42', unknown: 'bar') }

    it 'can have arbitrary properties' do
      expect { test_instance }.not_to raise_error
      expect( test_instance[:unknown] ).to eq('bar')
    end

    it 'uses type casting for defined properties' do
      expect( test_instance.known ).to be_kind_of(Integer)
    end
  end

  describe 'sensitive properties' do
    let(:test_class) { self.class::TestSecretObject }
    let(:obj) { test_class.new(username: 'alice', password: 's3cret', api_key: 'k3y') }

    it 'masks sensitive attribute values in #inspect' do
      output = obj.inspect
      expect(output).to include('username="alice"')
      expect(output).to include('password="[FILTERED]"')
      expect(output).to include('api_key="[FILTERED]"')
      expect(output).not_to include('s3cret')
      expect(output).not_to include('k3y')
    end

    it 'omits unset sensitive attributes from #inspect (no FILTERED leak)' do
      obj_nil = test_class.new(username: 'alice')
      expect(obj_nil.inspect).to include('username="alice"')
      expect(obj_nil.inspect).not_to include('password')
      expect(obj_nil.inspect).not_to include('FILTERED')
    end

    it 'still serializes the real values via #as_json (wire format unchanged)' do
      json = obj.as_json
      expect(json[:attributes][:password]).to eq('s3cret')
      expect(json[:attributes][:api_key]).to eq('k3y')
    end
  end
end
