# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      class Base < ComplexObject::Base
        class << self
          protected

          # Resolves the subclass from the explicit TYPE_CLASSES map: the wire types
          # (sms_to_email, http_in, ...) are not pluralized class names. An unknown
          # type is wrapped in Generic so it round-trips through PATCH.
          def cast_single_object(hash)
            hash = hash.with_indifferent_access
            klass = SmsTrunkConfiguration::TYPE_CLASSES[hash[:type]]
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
