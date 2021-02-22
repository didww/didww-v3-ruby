module DIDWW
  module Resource
    class Identity < Base

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

      property :identity_type, type: :integer
      # Type: Integer
      # Description:
    end
  end
end
