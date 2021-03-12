# frozen_string_literal: true
module DIDWW
  module Resource
    class Identity < Base
      IDENTITY_TYPE_PERSONAL = 'Personal'
      IDENTITY_TYPE_BUSINESS = 'Business'

      has_one :country, class_name: 'Country'
      has_many :proofs, class_name: 'Proof'
      has_many :addresses, class_name: 'Address'
      has_many :permanent_documents, class_name: 'PermanentSupportingDocument'

      property :first_name, type: :string
      # Type: String
      # Description:

      property :last_name, type: :string
      # Type: String
      # Description:

      property :phone_number, type: :string
      # Type: String
      # Description:

      property :id_number, type: :string
      # Type: String
      # Description:

      property :birth_date, type: :date
      # Type: Date
      # Description:

      property :company_name, type: :string
      # Type: String
      # Description:

      property :company_reg_number, type: :string
      # Type: String
      # Description:

      property :vat_id, type: :string
      # Type: String
      # Description:

      property :description, type: :string
      # Type: String
      # Description:

      property :personal_tax_id, type: :string
      # Type: String
      # Description:

      property :identity_type, type: :string
      # Type: String
      # Description:

      property :created_at, type: :date
      # Type: Date
      # Description:

      def personal?
        identity_type == IDENTITY_TYPE_PERSONAL
      end

      def business?
        identity_type == IDENTITY_TYPE_BUSINESS
      end
    end
  end
end
