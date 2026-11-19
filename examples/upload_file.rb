# frozen_string_literal: true
# Encrypts a file with the DIDWW public keys and uploads it to encrypted_files.
# The printed ID is what a proof takes in its files (see identity_address_proofs.rb).
#
# DIDWW::Encrypt fetches the two public keys (GET /public_keys, sent without a
# token) and encrypts the file on the client: AES-256-CBC for the content, the
# AES key wrapped with RSA-OAEP for each public key. One file per upload request.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/upload_file.rb [file]
#        (defaults to examples/sample.pdf)

require 'bundler/setup'
require 'didww'
require 'stringio'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

path = ARGV.first || File.join(__dir__, 'sample.pdf')
name = File.basename(path)
content = File.binread(path)
puts "File: #{path} (#{content.bytesize} bytes)"

enc = DIDWW::Encrypt.new
encrypted = enc.encrypt(content)
puts "Encrypted: #{encrypted.bytesize} bytes"
puts "Fingerprint: #{enc.encryption_fingerprint}"

# A StringIO (or a File / Tempfile) can be rewound, so the upload is retried
# once with a new token when the first one is refused with 401.
file_id = DIDWW::Resource::EncryptedFile.upload(
  encryption_fingerprint: enc.encryption_fingerprint,
  file: Faraday::Multipart::FilePart.new(StringIO.new(encrypted), 'application/octet-stream', "#{name}.enc"),
  description: name
)

puts 'Upload successful!'
puts "Encrypted file ID: #{file_id}"

# EncryptedFile.upload_file(file, fingerprint) does the same for an object with
# #tempfile, #content_type and #original_filename, such as a Rack upload. It
# sends the file as it is, so the file must be encrypted already.
