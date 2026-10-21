# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      # Fallback for a configuration type this gem version does not know yet.
      # Keeps the type and attributes as received.
      class Generic < Base
        attr_reader :stored_type

        def initialize(params = {}, stored_type = nil)
          @stored_type = stored_type
          params.each { |k, v| attributes[k] = v }
        end

        def type
          stored_type || self.class.type
        end

        def as_json(*)
          { type: type, attributes: attributes.as_json }.with_indifferent_access
        end
      end
    end
  end
end
