# frozen_string_literal: true
require 'didww/complex_objects/did_order_item'
require 'didww/complex_objects/capacity_order_item'
require 'didww/callback/const'

module DIDWW
  module Resource
    class Order < Base
      include DIDWW::Callback::CONST

      # Possible values for order.status
      STATUS_PENDING      = 'Pending'
      STATUS_COMPLETED    = 'Completed'
      STATUS_CANCELLED    = 'Canceled'
      STATUSES = [
                   STATUS_PENDING,
                   STATUS_COMPLETED,
                   STATUS_CANCELLED
                 ].freeze

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
