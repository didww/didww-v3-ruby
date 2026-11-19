# frozen_string_literal: true
# Creates an identity and an address, encrypts and uploads a file, attaches a
# proof to the identity and one to the address, prints their verified flags,
# and deletes the address and the identity.
#
#   1. Create a personal identity with a country and a birth country (2026-04-16)
#   2. Create an address linked to the identity
#   3. Pick a proof type for each: entity_type "personal" and "address"
#   4. Encrypt sample.pdf and upload it twice, one file per proof
#   5. Create the proofs; DIDWW reviews them and sets verified later
#   6. Clean up, also when a step fails
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/identity_address_proofs.rb

require 'bundler/setup'
require 'didww'
require 'stringio'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

# Encrypts content and uploads it; returns the encrypted file ID
def upload_encrypted(enc, content, name)
  DIDWW::Resource::EncryptedFile.upload(
    encryption_fingerprint: enc.encryption_fingerprint,
    file: Faraday::Multipart::FilePart.new(StringIO.new(enc.encrypt(content)), 'application/octet-stream', "#{name}.enc"),
    description: name
  )
end

# entity is the identity or the address the proof is for
def create_proof(label, entity, proof_type, file_id)
  proof = DIDWW::Client.proofs.new
  proof.entity = entity
  proof.proof_type = proof_type
  proof.files = [DIDWW::Resource::EncryptedFile.load(id: file_id)]
  abort "Error creating #{label} proof: #{proof.errors.full_messages}" unless proof.save
  puts "Created #{label} proof: #{proof.id} (type=#{proof_type.name})"
end

country = DIDWW::Client.countries.where(iso: 'US').all.first
abort 'Country US not found' unless country
puts "Using country: #{country.name} (#{country.id})"

identity = nil
address = nil
file_ids = []
begin
  puts "\n=== Creating Identity ==="
  identity = DIDWW::Client.identities.new(
    identity_type: DIDWW::Resource::Identity::IDENTITY_TYPE_PERSONAL,
    first_name: 'John',
    last_name: 'Doe',
    phone_number: '12125551234'
  )
  identity.country = country
  identity.birth_country = country # 2026-04-16
  abort "Error creating identity: #{identity.errors.full_messages}" unless identity.save
  puts "Created identity: #{identity.id} (#{identity.first_name} #{identity.last_name})"

  puts "\n=== Creating Address ==="
  address = DIDWW::Client.addresses.new(
    city_name: 'New York',
    postal_code: '10001',
    address: '123 Main St'
  )
  address.identity = identity
  address.country = country
  abort "Error creating address: #{address.errors.full_messages}" unless address.save
  puts "Created address: #{address.id} (#{address.address})"

  puts "\n=== Proof Types ==="
  proof_types = DIDWW::Client.proof_types.all
  identity_proof_type = proof_types.find { |pt| pt.entity_type == DIDWW::Resource::Identity::IDENTITY_TYPE_PERSONAL }
  address_proof_type = proof_types.find { |pt| pt.entity_type == 'address' }
  abort 'No proof type for personal identities' unless identity_proof_type
  abort 'No proof type for addresses' unless address_proof_type
  puts "Identity proof type: #{identity_proof_type.name} (#{identity_proof_type.id})"
  puts "Address proof type: #{address_proof_type.name} (#{address_proof_type.id})"

  puts "\n=== Encrypting and Uploading Files ==="
  content = File.binread(File.join(__dir__, 'sample.pdf'))
  enc = DIDWW::Encrypt.new # fetches the public keys
  file_ids << upload_encrypted(enc, content, 'identity_proof.pdf')
  file_ids << upload_encrypted(enc, content, 'address_proof.pdf')
  puts "Uploaded encrypted files: #{file_ids.join(', ')}"

  puts "\n=== Creating Proofs ==="
  create_proof('identity', identity, identity_proof_type, file_ids[0])
  create_proof('address', address, address_proof_type, file_ids[1])

  puts "\n=== Verified Flags ==="
  puts "Identity #{identity.id}: verified=#{DIDWW::Client.identities.find(identity.id).first.verified}"
  puts "Address #{address.id}: verified=#{DIDWW::Client.addresses.find(address.id).first.verified}"
ensure
  puts "\n=== Cleaning Up ==="
  { 'address' => address, 'identity' => identity }.each do |label, resource|
    next unless resource&.persisted?

    if resource.destroy
      puts "Deleted #{label}: #{resource.id}"
    else
      puts "Error deleting #{label} #{resource.id}: #{resource.errors.full_messages}"
    end
  end
  file_ids.each do |file_id|
    file = DIDWW::Resource::EncryptedFile.load(id: file_id)
    if file.destroy
      puts "Deleted encrypted file: #{file_id}"
    else
      puts "Error deleting encrypted file #{file_id}: #{file.errors.full_messages}"
    end
  rescue JsonApiClient::Errors::NotFound
    puts "Encrypted file #{file_id} was removed with its proof"
  end
end
