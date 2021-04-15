# frozen_string_literal: true
module DIDWW
  module Resource
    class RequirementValidation < Base
      has_one :requirement, class_name: 'Requirement'
      has_one :address, class_name: 'Address'
      has_one :identity, class_name: 'Identity'
    end
  end
end
