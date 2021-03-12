# frozen_string_literal: true
require 'json_api_client/schema'

module DIDWW
  module ComplexObject
    class Base
      class << self
        # Specifies the JSON API resource type. By default this is inferred
        # from the resource class name.
        def type
          name.demodulize.underscore.pluralize
        end

        def property(name, options = {})
          property = schema.add(name, options)
          define_method(name.to_sym) { self[name] }
          define_method("#{name}=".to_sym) { |val| self[name] = val }
        end

        def schema
          @schema ||= JsonApiClient::Schema.new
        end

        # Type casting for JsonApiClient parser/setters
        def cast(value, default)
          case value
          when self
            value
          when Hash
            cast_single_object(value)
          when Array
            value.map { |item| cast(item, item) }
          else
            default
          end
        end

        protected

        def cast_single_object(hash)
          hash = hash.with_indifferent_access
          klass = class_for_type(hash[:type])
          klass ? klass.new(hash[:attributes] || {}) : hash
        end

        # Returns a ComplexObject class if given JSON API type matches any
        def class_for_type(type)
          "#{parent.name}::#{type.classify}".safe_constantize
        end
      end

      def type
        self.class.type
      end

      def attributes
        @attributes ||= ActiveSupport::HashWithIndifferentAccess.new
      end

      def initialize(params = {})
        params.each { |k, v| self[k] = v }
        self.class.schema.each_property do |property|
          attributes[property.name] = property.default unless attributes.has_key?(property.name) || property.default.nil?
        end
      end

      def [](key)
        attributes[key]
      end

      def []=(key, value)
        property = self.class.schema.find(key)
        attributes[key] = property ? property.cast(value) : value
      end

      # When we represent this resource for serialization (create/update), we do so
      # with this implementation
      def as_json(*)
        { type: type }.with_indifferent_access.tap do |h|
          h[:attributes] = attributes.as_json
        end
      end

      def as_json_api(*); as_json end
    end
  end
end

JsonApiClient::Schema.register complex_object: DIDWW::ComplexObject::Base
