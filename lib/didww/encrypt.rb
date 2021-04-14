# frozen_string_literal: true
require 'openssl'
require 'openssl/oaep'
require 'net/http'

module DIDWW
  # Allows to encrypt file on Ruby-side before uploading to `/v3/encrypted_files`.
  # @example
  #   file_content_1 = File.read('file_to_send_1.jpg', mode: 'rb')
  #   file_content_2 = File.read('file_to_send_1.pdf', mode: 'rb')
  #   enc = DIDWW::Encrypt.new
  #   enc_data_1 = enc.encrypt(file_content_1)
  #   enc_data_2 = enc.encrypt(file_content_2)
  #   enc_io_1 = Faraday::UploadIO.new(StringIO.new(enc_data_1), 'application/octet-stream')
  #   enc_io_2 = Faraday::UploadIO.new(StringIO.new(enc_data_2), 'application/octet-stream')
  #   DIDWW::Resource::EncryptedFile.upload(
  #     encryption_fingerprint: enc.encryption_fingerprint,
  #     items: [
  #       { file: enc_io_1, description: 'file_to_send_1.jpg' },
  #       { file: enc_io_2, description: 'file_to_send_2.pdf' }
  #     ]
  #   ) # => Array if IDs
  #
  class Encrypt
    AES_ALGO = [256, :CBC]
    AES_KEY_LEN = 32
    AES_IV_LEN = 16
    LABEL = ''
    SEPARATOR = ':::'

    class << self
      # @param binary [String]
      # @return [String]
      def encrypt(binary)
        new.encrypt(binary)
      end
    end

    attr_reader :public_keys, :encryption_fingerprint

    def initialize
      reset!
    end

    # @param binary [String] binary content of a file.
    # @return [String] binary content of an encrypted file.
    def encrypt(binary)
      aes_key, aes_iv, encrypted_aes = encrypt_aes(binary)
      aes_credentials = aes_key + aes_iv
      encrypted_rsa_a = encrypt_rsa_oaep(public_keys[0], aes_credentials)
      encrypted_rsa_b = encrypt_rsa_oaep(public_keys[1], aes_credentials)
      encrypted_rsa_a + encrypted_rsa_b + encrypted_aes
    end

    # Resets public keys and fingerprint.
    def reset!
      @public_keys = fetch_public_keys
      @encryption_fingerprint = calculate_fingerprint
    end

    private

    # @return [Array(String,String)] public keys.
    def fetch_public_keys
      DIDWW::Resource::PublicKey.find.map(&:key)
    end

    def calculate_fingerprint
      public_keys.map { |pub_key| fingerprint_for(pub_key) }.join(SEPARATOR)
    end

    # @param public_key [String] PEM public key.
    # @return [String] hexstring digest SHA1 for public key binary.
    def fingerprint_for(public_key)
      public_key += "\n" unless public_key[-1] == "\n"
      public_key_base64 = public_key.split("\n")[1..-2].join
      public_key_bin = Base64.decode64(public_key_base64)
      OpenSSL::Digest::SHA1.hexdigest(public_key_bin)
    end

    # @param public_key [String]
    # @param text [String]
    def encrypt_rsa_oaep(public_key, text)
      rsa = OpenSSL::PKey::RSA.new(public_key)
      rsa.public_encrypt_oaep(text, LABEL, OpenSSL::Digest::SHA256)
    end

    # @param binary [String]
    # @return [Array(String,String,String)] binaries key, vector, encrypted data.
    def encrypt_aes(binary)
      key = SecureRandom.random_bytes(AES_KEY_LEN)
      iv = SecureRandom.random_bytes(AES_IV_LEN)
      cipher = OpenSSL::Cipher::AES.new(*AES_ALGO)
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      encrypted = cipher.update(binary) + cipher.final
      [key, iv, encrypted]
    end
  end
end
