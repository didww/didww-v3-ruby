# frozen_string_literal: true

require 'didww/resource/concerns/has_status_helpers'

module DIDWW
  module Resource
    # Verification of a sender identity used for outbound messages.
    # Supported operations: index, show, update. Only name and sms_trunk can be changed,
    # and a closed verification cannot be updated.
    #
    # Server-side filters: status, sender_type, sms_trunk.id, name, reference.
    #
    # meta carries: setup_price, monthly_price.
    class SenderIdVerification < Base
      include HasStatusHelpers

      STATUS_ACTIVE = 'active'
      STATUS_CHANGES_REQUIRED = 'changes_required'
      STATUS_CLOSED = 'closed'
      STATUS_CLOSING_IN_PROCESS = 'closing_in_process'
      STATUS_IN_PROCESS = 'in_process'
      STATUS_NEW = 'new'

      STATUSES = [
        STATUS_ACTIVE,
        STATUS_CHANGES_REQUIRED,
        STATUS_CLOSED,
        STATUS_CLOSING_IN_PROCESS,
        STATUS_IN_PROCESS,
        STATUS_NEW
      ].freeze

      SENDER_TYPE_ALPHANUMERIC = 'alphanumeric'
      SENDER_TYPE_CARRIER = 'carrier'
      SENDER_TYPE_LONG_CODE = 'long_code'
      SENDER_TYPE_SHORT_CODE = 'short_code'
      SENDER_TYPE_TOLL_FREE = 'toll_free'

      SENDER_TYPES = [
        SENDER_TYPE_ALPHANUMERIC,
        SENDER_TYPE_CARRIER,
        SENDER_TYPE_LONG_CODE,
        SENDER_TYPE_SHORT_CODE,
        SENDER_TYPE_TOLL_FREE
      ].freeze

      has_one :sms_trunk, class_name: 'SmsTrunk'
      has_many :countries, class_name: 'Country'
      has_many :dids, class_name: 'Did'
      has_one :order, class_name: 'Order'
      has_one :identity, class_name: 'Identity'
      has_one :address, class_name: 'Address'

      property :name, type: :string
      # Type: String
      # Description: Name of the verification

      property :status, type: :string
      # Type: String
      # Description: One of STATUSES. Read-only.

      property :sender_type, type: :string
      # Type: String
      # Description: One of SENDER_TYPES. Read-only.

      property :sender_ids, type: :array
      # Type: Array<String>
      # Description: Sender IDs the verification covers; for long_code and toll_free, the numbers
      #              of the DIDs. Read-only.

      property :reference, type: :string
      # Type: String
      # Description: Human-readable reference. Read-only.

      property :reject_reasons, type: :array
      # Type: Array<String>
      # Nullable: Yes
      # Description: Reasons the last submission was rejected; nil unless changes_required, and when
      #              there are none. Read-only.

      property :reject_comment, type: :string
      # Type: String
      # Nullable: Yes
      # Description: Reviewer comment on the rejection; nil unless changes_required. Read-only.

      property :renew_date, type: :string
      # Type: String
      # Nullable: Yes
      # Description: Next renewal date, "YYYY-MM-DD"; nil once closed. Read-only.

      property :created_at, type: :time
      # Type: Time
      # Description: Read-only.

      property :activated_at, type: :time
      # Type: Time
      # Nullable: Yes
      # Description: Read-only.

      property :closed_at, type: :time
      # Type: Time
      # Nullable: Yes
      # Description: Read-only.

      status_helper :active,             STATUS_ACTIVE
      status_helper :changes_required,   STATUS_CHANGES_REQUIRED
      status_helper :closed,             STATUS_CLOSED
      status_helper :closing_in_process, STATUS_CLOSING_IN_PROCESS
      status_helper :in_process,         STATUS_IN_PROCESS
      # "new" collides with Class.new, so expose the predicate as new_status?
      status_helper :new_status,         STATUS_NEW
    end
  end
end
