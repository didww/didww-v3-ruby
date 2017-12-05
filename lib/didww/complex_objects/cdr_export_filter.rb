require 'json_api_client/schema'

module DIDWW
  module ComplexObject
    class CdrExportFilter < Base
      # Type casting for JsonApiClient parser/setters
      def self.cast_single_object(hash)
        new(hash)
      end

      property :year,       type: :integer
      property :month,      type: :integer
      property :did_number, type: :string

      def as_json(*)
        super[:attributes]
      end

    end
  end
end

JsonApiClient::Schema.register cdr_export_filter: DIDWW::ComplexObject::CdrExportFilter
