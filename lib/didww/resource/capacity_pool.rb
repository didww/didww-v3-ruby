# frozen_string_literal: true
module DIDWW
  module Resource
    class CapacityPool < Base
      has_many :countries, class_name: 'Country'
      has_many :shared_capacity_groups, class_name: 'SharedCapacityGroup'
      has_many :qty_based_pricings, class_name: 'QtyBasedPricing'

      property :name, type: :string
      # Type: String
      # Description: Capacity pool name

      property :renew_date, type: :string
      # Type: String
      # Description: Next monthly renew date in format 'YYYY-MM-DD'

      property :total_channels_count, type: :integer
      # Type: Integer
      # Description: Channels count owned by customer in this pool

      property :assigned_channels_count, type: :integer
      # Type: Integer
      # Description: Channels used by at least one service in this pool

      property :minimum_limit, type: :integer
      # Type: Integer
      # Description: A minimum amount of channels in this pool. Customer cannot remove unassigned channels below this level.

      property :minimum_qty_per_order, type: :integer
      # Type: Integer
      # Description: A minimum amount of new channels to add to this pool in one order.

      property :setup_price, type: :decimal
      # Type: String
      # Description: Non-recurring price per channel

      property :monthly_price, type: :decimal
      # Type: String
      # Description: Monthly recurring price per channel

      property :metered_rate, type: :decimal
      # Type: String
      # Description: Metered rate per minute

    end
  end
end
