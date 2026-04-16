# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module AuthenticationMethod
      # Fallback class used when the server returns an authentication_method
      # of a type this gem version does not know about yet. Preserves the
      # unrecognized type and attributes so callers can introspect and
      # round-trip them back to the server without data loss.
      #
      # When a new authentication method type ships server-side, the gem
      # should be updated to add a dedicated subclass; Generic exists so
      # forward deployments don't silently downgrade to raw Hashes.
      class Generic < Base
        attr_reader :stored_type

        def initialize(params = {}, stored_type = nil)
          @stored_type = stored_type
          # Keep unknown attributes in the attributes hash, since we have no
          # property DSL declarations to validate against.
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
