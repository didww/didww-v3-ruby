# frozen_string_literal: true
require 'didww/prices/price'

module DIDWW
  module Prices
    class SmsOutPrice < Price
      attribute :source_prefix
      # Type: String
      # Nullable: true
      # Description: Prefix of the sending number; null for any number

      attribute :destination_prefix
      # Type: String
      # Nullable: true
      # Description: Destination prefix; null for any destination

      attribute :country
      # Type: String
      # Nullable: true
      # Description: Destination country name

      attribute :mcc, :integer
      # Type: Integer
      # Nullable: true
      # Description: Mobile country code; null for any network

      attribute :mcc_name
      # Type: String
      # Nullable: true
      # Description: Name of the mobile country code

      attribute :mnc, :integer
      # Type: Integer
      # Nullable: true
      # Description: Mobile network code; null for any network of the country

      attribute :mnc_name
      # Type: String
      # Nullable: true
      # Description: Name of the mobile network

      attribute :reject_sms, :boolean
      # Type: Boolean
      # Description: The plan rejects SMS to this destination

      attribute :price, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Price per SMS in USD, VAT excluded; null when reject_sms is true
    end
  end
end
