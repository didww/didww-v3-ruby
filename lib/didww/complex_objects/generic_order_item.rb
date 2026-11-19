# frozen_string_literal: true
module DIDWW
  module ComplexObject
    # An order item for any other charge, such as a Sender ID verification.
    # It is returned only; orders are not created with it.
    class GenericOrderItem < Base
      property :qty,           type: :int
      property :nrc,           type: :decimal
      property :mrc,           type: :decimal
      property :prorated_mrc,  type: :boolean
      property :billed_from,   type: :string
      property :billed_to,     type: :string
    end
  end
end
