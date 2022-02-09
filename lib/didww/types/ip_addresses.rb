# frozen_string_literal: true

module DIDWW
  module Types
    module IpAddresses
      module_function

      def cast(values, default)
        return default unless values.is_a?(Array)

        values.map do |value|
          cast_item(value)
        end
      rescue IPAddr::Error
        default
      end

      def cast_item(value)
        value.is_a?(IPAddr) ? value : IPAddr.new(value)
      end
    end
  end
end
