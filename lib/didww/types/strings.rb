# frozen_string_literal: true

module DIDWW
  module Types
    module Strings
      module_function

      def cast(values, default)
        return default unless values.is_a?(Array)

        values.map do |value|
          cast_item(value)
        end
      end

      def cast_item(value)
        value.to_s
      end
    end
  end
end
