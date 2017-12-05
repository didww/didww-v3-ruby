module DIDWW
  module Resource
    class Balance < Base
      def self.table_name
        'balance'
      end
      property :balance, type: :decimal
      # Type: String
      # Description: Prepaid balance

      property :credit, type: :decimal
      # Type: String
      # Description: Available credit

      property :total_balance, type: :decimal
      # Type: String
      # Description: The net balance (balance + credit)
    end
  end
end
