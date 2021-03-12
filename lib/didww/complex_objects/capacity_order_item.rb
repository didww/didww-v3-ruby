# frozen_string_literal: true
module DIDWW
  module ComplexObject
    class CapacityOrderItem < Base
      # passed at order creation
      property :qty,                type: :int
      property :capacity_pool_id,   type: :string

      # returned
      property :nrc,                type: :decimal
      property :mrc,                type: :decimal
      property :propated_mrc,       type: :boolean
      property :billed_from,        type: :string
      property :billed_to,          type: :string
    end
  end
end
