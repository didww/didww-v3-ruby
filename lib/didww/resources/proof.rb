# frozen_string_literal: true
module DIDWW
  module Resource
    class Proof < Base

      has_many :files, class_name: 'EncryptedFile'
      has_one :proof_type, class_name: 'ProofType'
      has_one :entity, class_name: 'Entity', polymorphic: true

      property :created_at, type: :date
      # Type: Date
      # Description:

      property :is_expired, type: :boolean
      # Type: Boolean
      # Description:
    end
  end
end
