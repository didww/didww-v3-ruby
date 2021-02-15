module DIDWW
  module Resource
    class Requirement < Base

      has_one :country
      has_one :did_group_type
      has_one :personal_permanent_document
      has_one :business_permanent_document
      has_one :personal_onetime_document
      has_one :business_onetime_document
      has_many :personal_proof_types
      has_many :business_proof_types
      has_many :address_proof_types

      property :identity_type
      # Type:
      # Description:

      property :personal_area_level
      # Type:
      # Description:

      property :business_area_level
      # Type:
      # Description:

      property :address_area_level
      # Type:
      # Description:

      property :personal_proof_qty
      # Type:
      # Description:

      property :business_proof_qty
      # Type:
      # Description:

      property :address_proof_qty
      # Type:
      # Description:

      property :personal_mandatory_fields
      # Type:
      # Description:

      property :business_mandatory_fields
      # Type:
      # Description:

      property :service_description_required
      # Type:
      # Description:

      property :restriction_message
      # Type:
      # Description:
    end
  end
end
