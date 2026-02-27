# frozen_string_literal: true
module DIDWW
  module Resource
    class Country < Base
      has_many :regions, class_name: 'Region'

      property :name, type: :string
      # Type: String
      # Description: Country name

      property :prefix, type: :string
      # Type: String
      # Description: Country prefix (country calling code)

      property :iso, type: :string
      # Type: String
      # Description: Country ISO code
    end
  end
end
