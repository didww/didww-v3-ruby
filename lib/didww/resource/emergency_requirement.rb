# frozen_string_literal: true

require 'didww/resource/concerns/number_types'

module DIDWW
  module Resource
    # Requirements that must be satisfied before ordering an emergency
    # calling service for a given country/number_type. Introduced in API 2026-04-16.
    #
    # Each record also reports a price preview in `meta` (setup_price,
    # monthly_price), both decimal strings, when the customer has a matching
    # emergency plan.
    #
    # Server-side filters: country.id, number_type
    class EmergencyRequirement < Base
      include NumberTypes

      has_one :country, class_name: 'Country'

      property :identity_type, type: :string
      # Type: String
      # Description: Which kind of customer identity the emergency service accepts
      # (e.g. personal / business).

      property :address_area_level, type: :string
      # Type: String
      # Description: How precise the service address must be: country, area or city.

      property :personal_area_level, type: :string
      # Type: String, nullable
      # Description: How precise a personal identity address must be: world_wide or country.
      # Nil when the country does not accept a personal identity for emergency calling.

      property :business_area_level, type: :string
      # Type: String, nullable
      # Description: How precise a business identity address must be: world_wide or country.
      # Nil when the country does not accept a business identity for emergency calling.

      property :address_mandatory_fields, type: :array
      # Type: String[]
      # Description: Fields the service address must contain.

      property :personal_mandatory_fields, type: :array
      # Type: String[]
      # Description: Fields a personal identity must contain.

      property :business_mandatory_fields, type: :array
      # Type: String[]
      # Description: Fields a business identity must contain.

      property :estimate_setup_time, type: :string
      # Type: String
      # Description: Estimated time before emergency calling is enabled (e.g. "7-14 days").

      property :requirement_restriction_message, type: :string
      # Type: String, nullable
      # Description: Human-readable message describing any restrictions that
      # apply to ordering the service. Nil when the country places none.

      property :number_type, type: :string
      # Type: String
      # Description: Number type the rules apply to, one of NUMBER_TYPES.
    end
  end
end
