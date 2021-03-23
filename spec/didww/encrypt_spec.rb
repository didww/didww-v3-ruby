# frozen_string_literal: true
RSpec.describe DIDWW::Encrypt do
  let(:stub_public_keys_fetch) do
    stub_request(:get, "#{DIDWW::Client.api_base_url.chomp('/')}/public_keys")
      .and_return(
        status: 200,
        headers: { 'Content-Type' => 'application/vnd.api+json' },
        body: api_fixture('public_keys')
      )
  end

  describe '#encrypt' do
    subject do
      encryptor.encrypt(text)
    end

    before { stub_public_keys_fetch }
    let!(:encryptor) { DIDWW::Encrypt.new }

    # smallest PNG binary
    let(:text) do
      base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=='
      Base64.decode64(base64)
    end

    it 'encrypts successfully' do
      expect(subject).to be_present
      expect(stub_public_keys_fetch).to have_been_made.once
    end

    it 'fetch private keys only once' do
      expect(subject).to be_present
      expect(encryptor.encrypt('foobar')).to be_present
      expect(stub_public_keys_fetch).to have_been_made.once
    end

    it 'fetches keys again after reset!' do
      expect(subject).to be_present
      encryptor.reset!
      expect(encryptor.encrypt('foobar')).to be_present
      expect(encryptor.encrypt('barbaz')).to be_present
      expect(stub_public_keys_fetch).to have_been_made.twice
    end
  end

  describe '#encryption_fingerprint' do
    subject do
      encryptor.encryption_fingerprint
    end

    before { stub_public_keys_fetch }
    let!(:encryptor) { DIDWW::Encrypt.new }

    let(:expected_fingerprint) do
      'c24c8711fed0fb9df377d4dad6090038063eec27:::d8919eb961da809e4d597f5c072e04383055e219'
    end

    it 'encrypts successfully' do
      expect(subject).to be_present
      expect(encryptor.encryption_fingerprint).to be_present
      expect(stub_public_keys_fetch).to have_been_made.once
    end

    it 'fetch private keys only once' do
      expect(subject).to be_present
      expect(encryptor.encryption_fingerprint).to be_present
      expect(stub_public_keys_fetch).to have_been_made.once
    end

    it 'fetches keys again after reset!' do
      expect(subject).to be_present
      encryptor.reset!
      expect(encryptor.encryption_fingerprint).to be_present
      expect(encryptor.encryption_fingerprint).to be_present
      expect(stub_public_keys_fetch).to have_been_made.twice
    end
  end
end
