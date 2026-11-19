# frozen_string_literal: true
require 'bigdecimal'
require 'time'

module DIDWW
  module Prices
    # Every lookup answers JSON:API type "prices", so the row class is chosen by endpoint.
    class Price
      class << self
        def attributes
          @attributes ||= {}
        end

        # @param data [Hash] JSON:API resource object
        # @return [DIDWW::Prices::Price]
        def from_json_api(data)
          new(id: data['id'], attributes: data.fetch('attributes', {}))
        end

        private

        def attribute(name, type = :string)
          attributes[name] = type
          attr_reader name
        end
      end

      attr_reader :id

      def initialize(id: nil, attributes: {})
        @id = id
        values = attributes.transform_keys(&:to_sym)
        self.class.attributes.each { |name, type| instance_variable_set("@#{name}", coerce(values[name], type)) }
      end

      # @return [Hash]
      def to_h
        self.class.attributes.keys.each_with_object({ id: id }) { |name, hash| hash[name] = public_send(name) }
      end

      private

      def coerce(value, type)
        if value.nil?
          nil
        elsif type == :decimal
          BigDecimal(value.to_s)
        elsif type == :time
          Time.iso8601(value)
        else
          value
        end
      end
    end
  end
end
