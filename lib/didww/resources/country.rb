# frozen_string_literal: true
module DIDWW
  module Resource
    class Country < Base
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
