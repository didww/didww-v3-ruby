# frozen_string_literal: true
module DIDWW
  module Resource
    class ProofType < Base
      property :name, type: :string
      # Type: String
      # Description:

      property :entity_type, type: :string
      # Type: String
      # Description: What the document proves: address, business or personal.
    end
  end
end
