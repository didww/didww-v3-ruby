# frozen_string_literal: true
require 'didww/prices/price'

module DIDWW
  module Prices
    class VoiceInPrice < Price
      attribute :destination
      # Type: String
      # Description: Prefix of the plan that priced the number

      attribute :country
      # Type: String
      # Nullable: true
      # Description: Destination country name

      attribute :src_country_name
      # Type: String
      # Nullable: true
      # Description: Source country name; null for a price of calls from any country

      attribute :source_type
      # Type: String
      # Description: Calling party category, such as "cellular" or "fixed"

      attribute :rate, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Per-minute rate in USD, VAT excluded; null when reject_calls is true

      attribute :connection_fee, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Fee charged once per call in USD, VAT excluded; null when reject_calls is true

      attribute :initial_interval, :integer
      # Type: Integer
      # Description: First billing increment, in seconds

      attribute :next_interval, :integer
      # Type: Integer
      # Description: Each following billing increment, in seconds

      attribute :reject_calls, :boolean
      # Type: Boolean
      # Description: The plan rejects calls to this destination
    end
  end
end
