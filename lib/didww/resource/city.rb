# frozen_string_literal: true
module DIDWW
  module Resource
    class City < Base
      has_one :country, class_name: 'Country'
      has_one :region, class_name: 'Region'
      has_one :area, class_name: 'Area'

      property :name, type: :string
      # Type: String
      # Description: City name
    end
  end
end
