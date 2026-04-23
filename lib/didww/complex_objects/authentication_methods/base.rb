# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module AuthenticationMethod
      class Base < ComplexObject::Base
        class << self
          protected

          # Override ComplexObject::Base.cast_single_object so an
          # authentication_method with a type this gem version doesn't
          # recognize is wrapped in a Generic instance (forward-compat)
          # rather than returned as a raw Hash. Unknown types therefore
          # keep a consistent surface (#type, #attributes, #as_json)
          # and round-trip through PATCH without data loss.
          def cast_single_object(hash)
            hash = hash.with_indifferent_access
            klass = class_for_type(hash[:type])
            if klass
              klass.new(hash[:attributes] || {})
            else
              Generic.new(hash[:attributes] || {}, hash[:type])
            end
          end
        end
      end
    end
  end
end
