# frozen_string_literal: true

require 'didww/resource/concerns/has_status_helpers'

module DIDWW
  module Resource
    # Verification record for an emergency calling service, containing the
    # address/DIDs being declared and the outcome of the compliance check.
    #
    # Supported operations: index, show, create. Introduced in API 2026-04-16.
    #
    # Server-side filters: emergency_calling_service.id, status.
    class EmergencyVerification < Base
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
      has_one :emergency_calling_service, class_name: 'EmergencyCallingService'
      has_many :dids, class_name: 'Did'

      property :reference, type: :string
      # Type: String
      # Description: verification reference code

      property :status, type: :string
      # Type: String
      # Description: One of STATUSES ("pending", "approved", "rejected").

      property :reject_reasons, type: :array
      # Type: Array<String> or nil
      # Description: List of reject reason codes when status is "rejected".

      property :reject_comment, type: :string
      # Type: String
      # Description: Optional free-form comment accompanying a rejection.

      property :callback_url, type: :string
      # Type: String
      # Description: valid URI for callbacks

      property :callback_method, type: :string
      # Type: String
      # Description: GET or POST

      property :external_reference_id, type: :string
      # Type: String
      # Description: Customer-supplied reference. Max 100 characters.

      property :created_at, type: :time
      # Type: Time

      status_helper :pending, STATUS_PENDING
      status_helper :approved, STATUS_APPROVED
      status_helper :rejected, STATUS_REJECTED
    end
  end
end
