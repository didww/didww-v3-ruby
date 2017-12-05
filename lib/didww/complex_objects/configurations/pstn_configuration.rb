module DIDWW
  module ComplexObject
    module Configuration
      class PstnConfiguration < Base
        property :dst, type: :string
        # Type: String
        # Nullable: No
        # Description: Phone number

        DEFAULTS = {}.freeze

        RECOMMENDED = {}.freeze
      end
    end
  end
end
