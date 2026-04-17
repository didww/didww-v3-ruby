# frozen_string_literal: true
require 'didww/resource/concerns/has_status_helpers'
module DIDWW
  module Resource
    class AddressVerification < Base
      include HasStatusHelpers
      STATUS_PENDING = 'pending'
      STATUS_APPROVED = 'approved'
      STATUS_REJECTED = 'rejected'
      STATUSES = [
        STATUS_PENDING,
        STATUS_APPROVED,
        STATUS_REJECTED
      ].freeze

      has_one :address, class_name: 'Address'
      has_many :dids, class_name: 'Did'
      has_many :onetime_files, class_name: 'EncryptedFile'

      property :service_description, type: :string
      # Type: String
      # Description:

      property :status, type: :string
      # Type: String
      # Description:

      property :reject_reasons, type: :array
      # Type: Array<String> or nil
      # Description: List of reject reasons

      property :created_at, type: :time
      # Type: Time
      # Description:

      property :callback_url, type: :string
      # Type: String
      # Description: valid URI for callbacks

      property :callback_method, type: :string
      # Type: String
      # Description: GET or POST

      property :reference, type: :string
      # Type: String
      # Description: verification reference code

      property :reject_comment, type: :string
      # Type: String
      # Description: Optional free-form comment accompanying a rejection. (API 2026-04-16)

      property :external_reference_id, type: :string
      # Type: String
      # Description: Customer-supplied reference. Max 100 characters. (API 2026-04-16)

      status_helper :pending, STATUS_PENDING
      status_helper :approved, STATUS_APPROVED
      status_helper :rejected, STATUS_REJECTED

    end
  end
end
