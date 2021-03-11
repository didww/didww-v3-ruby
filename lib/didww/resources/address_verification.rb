module DIDWW
  module Resource
    class AddressVerification < Base

      has_one :address, class_name: 'Address'
      has_many :dids, class_name: 'Did'
      has_many :onetime_files, class_name: 'EncryptedFile'

      property :service_description, type: :string
      # Type: String
      # Description:

      property :status, type: :string
      # Type: String
      # Description:

      property :created_at, type: :date
      # Type: Date
      # Description:
    end
  end
end
