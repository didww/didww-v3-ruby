# frozen_string_literal: true
module DIDWW
  module Resource
    class AvailableDid < Base
      has_one :did_group
      has_one :nanpa_prefix

      property :number, type: :string
      # Type: String
      # Description: The actual DID number in the format [country code][area code][subscriber number].

    end
  end
end
