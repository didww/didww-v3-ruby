# frozen_string_literal: true
module DIDWW
  module Resource
    class PermanentSupportingDocument < Base

      has_many :files, class_name: 'EncryptedFile'
      has_one :template, class_name: 'SupportingDocumentTemplate'
      has_one :identity, class_name: 'Identity'

      property :created_at, type: :time
      # Type: Time
      # Description:

      property :external_reference_id, type: :string
      # Type: String
      # Description: Customer-supplied reference. Max 100 characters. (API 2026-04-16)
    end
  end
end
