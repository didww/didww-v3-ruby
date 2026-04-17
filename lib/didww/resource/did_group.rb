# frozen_string_literal: true
module DIDWW
  module Resource
    class DidGroup < Base
      # Possible values for did_group.features array
      FEATURE_VOICE_IN = 'voice_in'
      FEATURE_VOICE_OUT = 'voice_out'
      FEATURE_T38 = 't38'
      FEATURE_IN_SMS = 'sms_in'
      FEATURE_P2P = 'p2p'             # (API 2026-04-16)
      FEATURE_A2P = 'a2p'             # (API 2026-04-16)
      FEATURE_EMERGENCY = 'emergency' # (API 2026-04-16)
      FEATURE_CNAM_OUT = 'cnam_out'   # (API 2026-04-16)

      has_one :country, class_name: 'Country'
      has_one :city,    class_name: 'City'
      has_one :did_group_type, class_name: 'DidGroupType'
      has_one :region, class_name: 'Region'
      has_many :stock_keeping_units, class_name: 'StockKeepingUnit'
      has_one :address_requirement, class_name: 'AddressRequirement'

      property :area_name, type: :string
      # Type: String
      # Description: DID Group area name. This will be the name of the city, or a designation applicable to the area code such as "National".

      property :prefix, type: :string
      # Type: String
      # Description: DID Group prefix (city or area calling code)

      property :features, type: :complex_object  # TODO implement array of strings?
      # Type: Array of strings
      # Description: Features available for the DID Group, including voice, sms and t38. A DID Group may have multiple features.

      property :is_metered, type: :boolean
      # Type: Boolean
      # Description: Defines if the DID Group supports metered services (per-minute billing).

      property :allow_additional_channels, type: :boolean
      # Type: Boolean
      # Description: Defines if channel capacity may be added to this DID Group.

      property :service_restrictions, type: :string
      # Type: String
      # Description: Service restriction message associated with this DID Group, if any.
      #              Null when no restrictions apply. (API 2026-04-16)

      # TODO
      # Meta attributes
      #
      # :available_dids_enabled
      # Type: Boolean
      # Description: Defines if particular DID from this DID group can be ordered via available_dids or did_reservations.
      #
      # needs_registration
      # Type: Boolean
      # Description: Defines if end-user registration is required for this DID Group.
      #
      # is_available
      # Type: Boolean
      # Description: Defines if numbers in this DID Group are currently in stock.

    end
  end
end
