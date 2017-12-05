require 'didww/middleware'
require 'didww/complex_objects/base'

module DIDWW
  module Resource
    class Base < JsonApiClient::Resource
      def as_json_api(*args)
        serialize_complex_attributes(super(*args))
      end

      private

      def serialize_complex_attributes(hash)
        # Replace complex objects with their json_api representation
        attributes = hash[:attributes]
        hash[:attributes] = Hash[attributes.map do |k, v|
          if v.respond_to?(:as_json_api)
            [k, v.as_json_api]
          elsif v.is_a?(Array)
            [k, v.map { |i| i.respond_to?(:as_json_api) ? i.as_json_api : i }]
          else
            [k, v]
          end
        end].with_indifferent_access
        return hash
      end
    end
  end
end
