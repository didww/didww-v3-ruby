# frozen_string_literal: true
require 'didww/prices/price'

module DIDWW
  module Prices
    class VoiceOutPrice < Price
      CATEGORY_INTERNATIONAL = 'International'
      CATEGORY_ORIGIN_BASED = 'Origin based'
      CATEGORY_LOCAL = 'Local'
      CATEGORIES = [
        CATEGORY_INTERNATIONAL,
        CATEGORY_ORIGIN_BASED,
        CATEGORY_LOCAL
      ].freeze

      attribute :prefix
      # Type: String
      # Description: Destination prefix of the plan that priced the number, plain digits

      attribute :country
      # Type: String
      # Nullable: true
      # Description: Destination country name

      attribute :network
      # Type: String
      # Nullable: true
      # Description: Destination network name

      attribute :rate, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Per-minute rate in USD, VAT excluded; null when reject_calls is true

      attribute :connection_fee, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Fee charged once per call in USD, VAT excluded; null when reject_calls is true

      attribute :initial_increment, :integer
      # Type: Integer
      # Description: First billing increment, in seconds

      attribute :recurring_increment, :integer
      # Type: Integer
      # Description: Each following billing increment, in seconds

      attribute :next_rate, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Per-minute rate from effective_at on

      attribute :next_connection_fee, :decimal
      # Type: BigDecimal
      # Nullable: true
      # Description: Connection fee from effective_at on

      attribute :next_initial_increment, :integer
      # Type: Integer
      # Nullable: true
      # Description: First billing increment from effective_at on

      attribute :next_recurring_increment, :integer
      # Type: Integer
      # Nullable: true
      # Description: Each following billing increment from effective_at on

      attribute :effective_at, :time
      # Type: Time
      # Nullable: true
      # Description: When the change named by comment takes effect

      attribute :comment
      # Type: String
      # Nullable: true
      # Description: Scheduled change, such as "Increase", "Connection fee change", "Billing increment change",
      #              "No Change", "Reject calls", "Removed" or "New Breakout"

      attribute :reject_calls, :boolean
      # Type: Boolean
      # Description: The plan rejects calls to this destination

      attribute :category
      # Type: String
      # Description: One of CATEGORIES
    end
  end
end
