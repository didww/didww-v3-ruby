# frozen_string_literal: true
module DIDWW
  module ComplexObject
    class EmergencyOrderItem < Base
      # passed at order creation
      property :qty,                          type: :int
      property :emergency_calling_service_id, type: :string

      # returned
      property :nrc,           type: :decimal
      property :mrc,           type: :decimal
      property :prorated_mrc,  type: :boolean
      property :billed_from,   type: :string
      property :billed_to,     type: :string
    end
  end
end
