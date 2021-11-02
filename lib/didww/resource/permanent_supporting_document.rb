# frozen_string_literal: true
module DIDWW
  module Resource
    class PermanentSupportingDocument < Base

      has_many :files, class_name: 'EncryptedFile'
      has_one :template, class_name: 'SupportingDocumentTemplate'
      has_one :identity, class_name: 'Identity'

      property :created_at, type: :date
      # Type: Date
      # Description:
    end
  end
end
