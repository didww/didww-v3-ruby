# frozen_string_literal: true
module DIDWW
  module Resource
    class DidGroupType < Base
      property :name, type: :string
      # Type: String
      # Description: DID Group Type name, such as "Local", "Mobile" or "Toll-free".
    end
  end
end
