# frozen_string_literal: true
RSpec.describe DIDWW::Resource::AddressRequirementValidation do
  it_behaves_like 'a requirement validation',
                  DIDWW::Resource::AddressRequirementValidation,
                  requirement_relationship: :address_requirement,
                  client_accessor: :address_requirement_validation,
                  path: 'address_requirement_validations'
end
