module DIDWW
  module Resource
    class StockKeepingUnit < Base
      belongs_to :did_group

      property :setup_price, type: :decimal
      # Type: String
      # Description: price for Order creation

      property :monthly_price, type: :decimal
      # Type: String
      # Description: monthly price for order renew

      property :channels_included_count, type: :integer
      # Type: Integer
      # Description: included channels capacity for each DID
    end
  end
end
