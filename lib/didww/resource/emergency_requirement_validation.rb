# frozen_string_literal: true

module DIDWW
  module Resource
    # Validates a prospective emergency calling service order against
    # an EmergencyRequirement, given an Address and an Identity.
    #
    # Write-only endpoint: a successful POST returns 204 No Content.
    # Any validation failures are returned as JSONAPI errors.
    #
    # Introduced in API 2026-04-16.
    class EmergencyRequirementValidation < Base
      has_one :emergency_requirement, class_name: 'EmergencyRequirement'
      has_one :address, class_name: 'Address'
      has_one :identity, class_name: 'Identity'
    end
  end
end
