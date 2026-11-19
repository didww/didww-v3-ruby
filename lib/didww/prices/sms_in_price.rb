# frozen_string_literal: true
require 'didww/prices/price'

module DIDWW
  module Prices
    class SmsInPrice < Price
      attribute :source_prefix
      # Type: String
      # Nullable: true
      # Description: Prefix of the sending number; null for any number

      attribute :source_number_length_min, :integer
      # Type: Integer
      # Description: Shortest sending number, in digits

      attribute :source_number_length_max, :integer
      # Type: Integer
      # Description: Longest sending number, in digits

      attribute :destination_prefix
      # Type: String
      # Nullable: true
      # Description: Prefix of the receiving number; null for any destination

      attribute :destination_number_length_min, :integer
      # Type: Integer
      # Description: Shortest receiving number, in digits

      attribute :destination_number_length_max, :integer
      # Type: Integer
      # Description: Longest receiving number, in digits

      attribute :country
      # Type: String
      # Nullable: true
      # Description: Country of the receiving number

      attribute :price, :decimal
      # Type: BigDecimal
      # Description: Price per SMS in USD, VAT excluded
    end
  end
end
