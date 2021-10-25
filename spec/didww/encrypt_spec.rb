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
  let(:private_keys_data) do
    JSON.parse(api_fixture('private_keys'), symbolize_names: true)
  end

  def decrypt(encrypted_binary, private_key, key_index)
    encrypted_aes_credentials = key_index == 0 ? encrypted_binary[0...512] : encrypted_binary[512...1024] # 512 bytes
    encrypted_aes_data = encrypted_binary[1024..-1] # from 1025 byte to the end
    rsa = OpenSSL::PKey::RSA.new(private_key)
    aes_credentials = rsa.private_decrypt_oaep(encrypted_aes_credentials, '', OpenSSL::Digest::SHA256)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    cipher.decrypt
    cipher.key = aes_credentials[0...32] # 32 bytes
    cipher.iv = aes_credentials[32..-1] # 16 bytes
    return cipher.update(encrypted_aes_data) + cipher.final
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

    it 'decrypts successfully with first key' do
      decrypted = decrypt(subject, private_keys_data[:private_key_a], 0)
      expect(decrypted).to eq(text)
    end

    it 'decrypts successfully with second key' do
      decrypted = decrypt(subject, private_keys_data[:private_key_b], 1)
      expect(decrypted).to eq(text)
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
