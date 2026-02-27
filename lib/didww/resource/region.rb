# frozen_string_literal: true
module DIDWW
  module Resource
    class Region < Base
      has_one :country, class_name: 'Country'

      property :name, type: :string
      # Type: String
      # Description: Region name
    end
  end
end
