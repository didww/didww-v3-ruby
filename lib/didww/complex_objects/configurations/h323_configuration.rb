# frozen_string_literal: true
module DIDWW
  module ComplexObject
    module Configuration
      class H323Configuration < Base
        property :dst, type: :string
        # Type: String
        # Nullable: No
        # Description: Phone number

        property :host, type: :string
        # Type: String
        # Nullable: No
        # Description: Destination server

        property :port, type: :string
        # Type: String
        # Nullable: No
        # Description: Destination port

        property :codec_ids, type: :array
        # TODO array type
        # Type: Array
        # Nullable: No
        # Description:

        DEFAULTS = {
          codec_ids: DEFAULT_CODEC_IDS,
          dst: DID_PLACEHOLDER,
        }.freeze

        RECOMMENDED = {}.freeze
      end
    end
  end
end
