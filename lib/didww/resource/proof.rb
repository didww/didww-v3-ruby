# frozen_string_literal: true
module DIDWW
  module Resource
    class Proof < Base

      has_many :files, class_name: 'EncryptedFile'
      has_one :proof_type, class_name: 'ProofType'
      has_one :entity, class_name: 'Entity', polymorphic: true

      property :created_at, type: :time
      # Type: Time
      # Description:

      property :expires_at, type: :time
      # Type: Time
      # Description: expiration date of the proof

      property :external_reference_id, type: :string
      # Type: String
      # Description: Customer-supplied reference. Max 100 characters. (API 2026-04-16)
    end
  end
end
