# frozen_string_literal: true
module DIDWW
  module Resource
    class DidGroup < Base
      module CONST
        # Possible values for did_group.features array
        FEATURE_VOICE    = 'voice'                           .freeze
        FEATURE_T38      = 't38'                             .freeze
        FEATURE_SMS      = 'sms'                             .freeze
        FEATURES = {
          FEATURE_VOICE => 'Voice'                           .freeze,
          FEATURE_T38   => 'T.38 Fax'                        .freeze,
          FEATURE_SMS   => 'SMS'                             .freeze
        }.freeze

        def features_human
          Array.wrap(features).map { |f| FEATURES[f] }
        end
      end

      include CONST

      has_one :country, class: Country
      has_one :city,    class: City

      property :area_name, type: :string
      # Type: String
      # Description: DID Group area name. This will be the name of the city, or a designation applicable to the area code such as "National".

      property :prefix, type: :string
      # Type: String
      # Description: DID Group prefix (city or area calling code)

      property :local_prefix, type: :string
      # Type: String
      # Description: DID Group local prefix

      property :features, type: :complex_object  # TODO implement array of strings?
      # Type: Array of strings
      # Description: Features available for the DID Group, including voice, sms and t38. A DID Group may have multiple features.

      property :is_metered, type: :boolean
      # Type: Boolean
      # Description: Defines if the DID Group supports metered services (per-minute billing).

      property :allow_additional_channels, type: :boolean
      # Type: Boolean
      # Description: Defines if channel capacity may be added to this DID Group.

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
