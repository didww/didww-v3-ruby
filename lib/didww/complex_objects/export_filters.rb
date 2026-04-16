# frozen_string_literal: true
require 'json_api_client/schema'

module DIDWW
  module ComplexObject
    class ExportFilters < Base
      # Type casting for JsonApiClient parser/setters
      def self.cast_single_object(hash)
        new(hash)
      end

      property :from,       type: :string # ISO 8601 / "YYYY-MM-DD HH:MM:SS" lower bound (cdr_in / cdr_out)
      property :to,         type: :string # ISO 8601 / "YYYY-MM-DD HH:MM:SS" upper bound (cdr_in / cdr_out)
      property :did_number, type: :string # only for CDR in
      property :voice_out_trunk_id, type: :string # only for CDR Out

      def as_json(*)
        result = attributes.as_json.with_indifferent_access
        result[:'voice_out_trunk.id'] = result.delete(:voice_out_trunk_id) if result.key?(:voice_out_trunk_id)
        result
      end

    end
  end
end
