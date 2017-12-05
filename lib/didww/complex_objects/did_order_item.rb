module DIDWW
  module ComplexObject
    class DidOrderItem < Base
      # passed at order creation
      property :qty,     type: :int
      property :sku_id,  type: :string

      # returned
      property :setup_price,    type: :decimal
      property :monthly_price,  type: :decimal
      property :did_group_id,   type: :string
    end
  end
end
