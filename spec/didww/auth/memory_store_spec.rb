# frozen_string_literal: true
RSpec.describe DIDWW::Auth::MemoryStore do
  subject(:store) { described_class.new(clock: clock) }

  let(:clock) { Struct.new(:now) { def call; now; end }.new(100.0) }

  describe '#read' do
    it 'returns nil for a missing key' do
      expect(store.read('key')).to be_nil
    end

    it 'returns the value before it expires' do
      store.write('key', 'value', expires_in: 60)
      clock.now += 59

      expect(store.read('key')).to eq('value')
    end

    it 'returns nil once the value expires' do
      store.write('key', 'value', expires_in: 60)
      clock.now += 60

      expect(store.read('key')).to be_nil
    end

    it 'drops the expired entry' do
      store.write('key', 'value', expires_in: 60)
      clock.now += 60
      store.read('key')

      expect(store.delete('key')).to be(false)
    end

    it 'keeps a value written without expires_in' do
      store.write('key', 'value')
      clock.now += 10**9

      expect(store.read('key')).to eq('value')
    end
  end

  describe '#write' do
    it 'replaces the value and its expiry' do
      store.write('key', 'old', expires_in: 60)
      clock.now += 30
      store.write('key', 'new', expires_in: 60)
      clock.now += 59

      expect(store.read('key')).to eq('new')
    end
  end

  describe '#delete' do
    it 'returns true when the key was stored' do
      store.write('key', 'value')

      expect(store.delete('key')).to be(true)
      expect(store.read('key')).to be_nil
    end

    it 'returns false when the key was not stored' do
      expect(store.delete('key')).to be(false)
    end
  end

  describe '#inspect' do
    it 'shows the number of entries without their values' do
      store.write('didww:token:v1:abc', { 'access_token' => 'secret-token' }, expires_in: 900)

      expect(store.inspect).to eq('#<DIDWW::Auth::MemoryStore entries=1>')
    end
  end
end
