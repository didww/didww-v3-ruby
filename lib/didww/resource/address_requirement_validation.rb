# frozen_string_literal: true
module DIDWW
  module Resource
    class AddressRequirementValidation < Base
      has_one :address_requirement, class_name: 'AddressRequirement'
      has_one :address, class_name: 'Address'
      has_one :identity, class_name: 'Identity'

      # This resource has no attributes — only relationships.
      def as_json_api(*)
        super.tap { |h| h.delete(:attributes) if h[:attributes].blank? }
      end
    end
  end
end
