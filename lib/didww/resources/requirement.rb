module DIDWW
  module Resource
    class Requirement < Base

      has_one :country, class_name: 'Country'
      has_one :did_group_type, class_name: 'DidGroupType', relation_name: :group_type
      has_one :personal_permanent_document, class_name: 'SupportingDocumentTemplate'
      has_one :business_permanent_document, class_name: 'SupportingDocumentTemplate'
      has_one :personal_onetime_document, class_name: 'SupportingDocumentTemplate'
      has_one :business_onetime_document, class_name: 'SupportingDocumentTemplate'
      has_many :personal_proof_types, class_name: 'Regulation::ProofType'
      has_many :business_proof_types, class_name: 'Regulation::ProofType'
      has_many :address_proof_types, class_name: 'Regulation::ProofType'

      property :identity_type, type: :integer
      # Type: Integer
      # Description:

      property :personal_area_level, type: :string
      # Type: String
      # Description:

      property :business_area_level, type: :string
      # Type: String
      # Description:

      property :address_area_level, type: :string
      # Type: String
      # Description:

      property :personal_proof_qty, type: :integer
      # Type: Integer
      # Description:

      property :business_proof_qty, type: :integer
      # Type: Integer
      # Description:

      property :address_proof_qty, type: :integer
      # Type: Integer
      # Description:

      property :personal_mandatory_fields, type: :array
      # Type: String[]
      # Description:

      property :business_mandatory_fields, type: :array
      # Type: String[]
      # Description:

      property :service_description_required, type: :boolean
      # Type: Boolean
      # Description:

      property :restriction_message, type: :string
      # Type: String
      # Description:
    end
  end
end
