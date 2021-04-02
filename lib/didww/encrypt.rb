# frozen_string_literal: true
require 'openssl'
require 'openssl/oaep'
require 'net/http'

module DIDWW
  # Allows to encrypt file on Ruby-side before uploading to `/v3/encrypted_files`.
  # @example
  #   encryptor = DIDWW::Encrypt.new
  #   encrypted_data = encryptor.encrypt(file.read)
  #   encryption_fingerprint = encryptor.encryption_fingerprint
  #   DIDWW::Resources::EncryptedFile.upload(
  #     encryption_fingerprint: encryption_fingerprint,
  #     items: [
  #       file: StringIO.new(encrypted_data),
  #       description: file.original_filename
  #     ]
  #   ) # => Array if IDs
  #
  class Encrypt
    AES_ALGO = [256, :CBC]
    AES_KEY_LEN = 32
    AES_IV_LEN = 16
    SALT_LEN = 16
    DATA_URI_PREFIX = 'data:application/octet-stream;base64,'
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

    def encrypt(binary)
      binary_base64 = "#{DATA_URI_PREFIX}#{Base64.encode64(binary)}"
      aes_key = SecureRandom.random_bytes(AES_KEY_LEN)
      aes_iv = SecureRandom.random_bytes(AES_IV_LEN)
      salt = SecureRandom.random_bytes(SALT_LEN)
      encrypted_aes = encrypt_aes(aes_key, aes_iv, binary_base64)
      aes_credentials = build_aes_credentials(aes_key, aes_iv)
      encrypted_rsa_a = encrypt_rsa_oaep(public_keys[0], aes_credentials)
      encrypted_rsa_b = encrypt_rsa_oaep(public_keys[1], aes_credentials)

      [
        Base64.encode64(encrypted_rsa_a),
        Base64.encode64(encrypted_rsa_b),
        Base64.encode64("#{salt}#{encrypted_aes}")
      ].join(SEPARATOR)
    end

    # Resets public keys and fingerprint.
    def reset!
      @public_keys = fetch_public_keys
      @encryption_fingerprint = calculate_fingerprint
    end

    private

    # @return [Array<String>] public keys.
    def fetch_public_keys
      DIDWW::Resource::PublicKey.find.map(&:key)
    end

    def calculate_fingerprint
      public_keys.map { |pub_key| fingerprint_for(pub_key) }.join(SEPARATOR)
    end

    def fingerprint_for(public_key)
      public_key += "\n" unless public_key[-1] == "\n"
      public_key_base64 = public_key.split("\n")[1..-2].join
      public_key_bin = Base64.decode64(public_key_base64)
      digest = OpenSSL::Digest::SHA1.digest(public_key_bin)

      # Binary to hex string
      binary_to_hex(digest)
    end

    # @param key [String] binary AES key.
    # @param iv [String] binary AES iv.
    # @return [String]
    def build_aes_credentials(key, iv)
      key_hex = binary_to_hex(key)
      iv_hex = binary_to_hex(iv)
      [key_hex, iv_hex].join(SEPARATOR)
    end

    # @param public_key [String]
    # @param text [String]
    def encrypt_rsa_oaep(public_key, text)
      rsa = OpenSSL::PKey::RSA.new(public_key)
      rsa.public_encrypt_oaep(text, LABEL, OpenSSL::Digest::SHA256)
    end

    # @param key [String] binary AES key.
    # @param iv [String] binary AES iv.
    # @param text [String]
    # @return [String]
    def encrypt_aes(key, iv, text)
      cipher = OpenSSL::Cipher::AES.new(*AES_ALGO)
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv

      cipher.update(text) + cipher.final
    end

    # Transforms binary string to hex string.
    # reversed operation:
    #   `hex.scan(/.{1,2}/).map { |byte| byte.to_i(16) }.pack('c*')`
    # param binary [String] binary string.
    # @return [String] hex string.
    def binary_to_hex(binary)
      binary.bytes.map { |byte| '%02x' % byte }.join
    end
  end
end
