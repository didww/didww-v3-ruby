module DIDWW
  module Resource
    class AddressVerification < Base
      STATUS_PENDING = 'Pending'
      STATUS_APPROVED = 'Approved'
      STATUS_REJECTED = 'Rejected'
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

      property :reject_reasons, type: :string
      # Type: String
      # Description:

      property :created_at, type: :date
      # Type: Date
      # Description:

      property :callback_url, type: :string
      # Type: String
      # Description: valid URI for callbacks

      property :callback_method, type: :string
      # Type: String
      # Description: GET or POST

      def pending?
        status == STATUS_PENDING
      end

      def approved?
        status == STATUS_APPROVED
      end

      def rejected?
        status == STATUS_REJECTED
      end

    end
  end
end
