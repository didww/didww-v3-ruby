# frozen_string_literal: true
RSpec.describe DIDWW::Resource::EmergencyRequirementValidation do
  it_behaves_like 'a requirement validation',
                  DIDWW::Resource::EmergencyRequirementValidation,
                  requirement_relationship: :emergency_requirement,
                  client_accessor: :emergency_requirement_validation,
                  path: 'emergency_requirement_validations'
end
