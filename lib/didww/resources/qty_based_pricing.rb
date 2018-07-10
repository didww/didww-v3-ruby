module DIDWW
  module Resource
    class QtyBasedPricing < Base
      belongs_to :capacity_pool

      property :qty, type: :integer
      # Type: Integer
      # Description: A treshold starting at which provided prices per channel apply

      property :setup_price, type: :decimal
      # Type: String
      # Description: Non-recurring price per channel

      property :monthly_price, type: :decimal
      # Type: String
      # Description: Monthly recurring price per channel
    end
  end
end
