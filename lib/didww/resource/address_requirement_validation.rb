# frozen_string_literal: true
module DIDWW
  module Resource
    class AddressRequirementValidation < Base
      has_one :address_requirement, class_name: 'AddressRequirement'
      has_one :address, class_name: 'Address'
      has_one :identity, class_name: 'Identity'
    end
  end
end
