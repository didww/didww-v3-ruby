module DIDWW
  module ComplexObject
    class DidOrderItem < Base
      # passed at order creation
      property :qty,                type: :int
      property :available_did_id,   type: :string
      property :did_reservation_id, type: :string
      property :sku_id,             type: :string

      # returned
      property :setup_price,        type: :decimal
      property :monthly_price,      type: :decimal
      property :did_group_id,       type: :string
    end
  end
end
