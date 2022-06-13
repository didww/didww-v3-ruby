# frozen_string_literal: true

module DIDWW
  module Resource
    class NanpaPrefix < Base
      has_one :country, class_name: Country
      has_one :region, class_name: Region

      property :npa, type: :string
      # Type: String
      # Description: NPA codes, or area codes consisting of three digits
      property :nxx, type: :string
      # Type: String
      # Description: Refer to three-digit code
      # that forms the second part of a 10-digit North American phone number
    end
  end
end
