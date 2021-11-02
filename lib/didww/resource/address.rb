# frozen_string_literal: true
module DIDWW
  module Resource
    class Address < Base

      has_one :identity, class_name: 'Identity'
      has_one :country, class_name: 'Country'
      has_many :proofs, class_name: 'Proof'
      has_many :city, class_name: 'City'
      has_many :area, class_name: 'Area'

      property :city_name, type: :string
      # Type: String
      # Description:

      property :postal_code, type: :string
      # Type: String
      # Description:

      property :address, type: :string
      # Type: String
      # Description:

      property :description, type: :string
      # Type: String
      # Description:

      property :created_at, type: :date
      # Type: Date
      # Description:

      property :verified, type: :boolean
      # Type: Boolean
      # Description:
    end
  end
end
