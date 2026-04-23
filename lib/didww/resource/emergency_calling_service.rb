# frozen_string_literal: true

require 'didww/resource/concerns/has_status_helpers'

module DIDWW
  module Resource
    # Customer-owned subscription to emergency calling on one or more DIDs.
    # Supported operations: index, show, destroy. Introduced in API 2026-04-16.
    #
    # Server-side filters: name, reference, country.id, did_group_type.id,
    # address.id, identity.id, status.
    #
    # meta carries: setup_price, monthly_price.
    class EmergencyCallingService < Base
      include HasStatusHelpers

      STATUS_ACTIVE = 'active'
      STATUS_CANCELED = 'canceled'
      STATUS_CHANGES_REQUIRED = 'changes_required'
      STATUS_IN_PROCESS = 'in_process'
      STATUS_NEW = 'new'
      STATUS_PENDING_UPDATE = 'pending_update'

      STATUSES = [
        STATUS_ACTIVE,
        STATUS_CANCELED,
        STATUS_CHANGES_REQUIRED,
        STATUS_IN_PROCESS,
        STATUS_NEW,
        STATUS_PENDING_UPDATE
      ].freeze

      has_one :country, class_name: 'Country'
      has_one :did_group_type, class_name: 'DidGroupType'
      has_one :order, class_name: 'Order'
      has_one :address, class_name: 'Address'
      has_one :emergency_requirement, class_name: 'EmergencyRequirement'
      has_one :emergency_verification, class_name: 'EmergencyVerification'
      has_many :dids, class_name: 'Did'

      property :name, type: :string
      # Type: String
      # Description: Human-readable name for the calling service subscription.

      property :reference, type: :string
      # Type: String
      # Description: server-assigned reference code

      property :status, type: :string
      # Type: String
      # Description: One of STATUSES ("active", "canceled", "changes_required",
      #   "in_process", "new", "pending_update").

      property :activated_at, type: :time
      # Type: Time
      # Description: Timestamp when the service became active. nil while pending.

      property :canceled_at, type: :time
      # Type: Time
      # Description: Timestamp when the service was canceled. nil when active.

      property :created_at, type: :time
      # Type: Time

      property :renew_date, type: :time
      # Type: Time
      # Description: Next renewal date. nil when canceled.

      status_helper :active,            STATUS_ACTIVE
      status_helper :canceled,          STATUS_CANCELED
      status_helper :changes_required,  STATUS_CHANGES_REQUIRED
      status_helper :in_process,        STATUS_IN_PROCESS
      # "new" collides with Class.new, so expose the predicate as new_status?
      status_helper :new_status,        STATUS_NEW
      status_helper :pending_update,    STATUS_PENDING_UPDATE
    end
  end
end
