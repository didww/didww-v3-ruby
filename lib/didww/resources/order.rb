require 'didww/complex_objects/did_order_item'
require 'didww/complex_objects/capacity_order_item'

module DIDWW
  module Resource
    class Order < Base
      module CONST
        # Possible values for order.status
        STATUS_PENDING      = 'Pending'                       .freeze
        STATUS_COMPLETED    = 'Completed'                     .freeze
        STATUS_CANCELLED    = 'Canceled'                      .freeze
        STATUSES = [
          STATUS_PENDING,
          STATUS_COMPLETED,
          STATUS_CANCELLED
        ].freeze
      end

      include CONST

      property :reference, type: :string
      # Type: String
      # Description: Order Reference

      property :amount, type: :decimal
      # Type: String
      # Description: Order Amount

      property :status, type: :string
      # Type: Enum
      # Description: Order status. One of "Pending", "Completed", "Canceled".

      property :description, type: :string
      # Type: String
      # Description: Order description

      property :created_at, type: :time
      # Type: DateTime
      # Description: Order created at DateTime

      property :items, type: :complex_object
      # Type: Array<OrderItem>
      # Description: Order items array

      property :allow_back_ordering, type: :boolean
      # Type: Boolean
      # Description: Allowing back ordering

      property :callback_url, type: :string
      # Type: String
      # Description: valid URI for callbacks

      property :callback_method, type: :string
      # Type: String
      # Description: GET or POST

      def initialize(*args)
        super
        self.items ||= []
      end

      def pending?
        STATUS_PENDING == status
      end

      def completed?
        STATUS_COMPLETED == status
      end

      def cancelled?
        STATUS_CANCELLED == status
      end

    end
  end
end
