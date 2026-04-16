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
      property :status, type: :string
      property :reject_reasons, type: :array
      property :reject_comment, type: :string
      property :callback_url, type: :string
      property :callback_method, type: :string
      property :external_reference_id, type: :string
      property :created_at, type: :time

      status_helper :pending, STATUS_PENDING
      status_helper :approved, STATUS_APPROVED
      status_helper :rejected, STATUS_REJECTED
    end
  end
end
