# frozen_string_literal: true
module DIDWW
  module Resource
    class Area < Base
      has_one :country, class_name: 'Country'

      property :name, type: :string
      # Type: String
      # Description: Regulatory Area name
    end
  end
end
