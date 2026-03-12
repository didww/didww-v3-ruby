# frozen_string_literal: true

module DIDWW
  module Resource
    module HasStatusHelpers
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def status_helper(method_name, status_value)
          define_method(:"#{method_name}?") { status == status_value }
        end
      end
    end
  end
end
