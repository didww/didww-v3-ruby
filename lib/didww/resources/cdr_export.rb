# frozen_string_literal: true
require 'forwardable'
require 'didww/complex_objects/cdr_export_filter'
require 'down/http'

module DIDWW
  module Resource
    class CdrExport < Base
      extend Forwardable

      STATUS_COMPLETED = 'Completed'

      property :filters, type: :cdr_export_filter
      # Type: CDR Export Filters Object
      # Nullable: No
      # Description: Filters

      property :status, type: :string
      # Type: String
      # Nullable: false
      # Description: status can be "Pending", "Processing" or "Completed"

      property :created_at, type: :time
      # Type: DateTime
      # Nullable: false
      # Description: timestamp when export request was created

      property :url, type: :string
      # Type: String
      # Nullable: true
      # Description: url of csv file for downloading. available only when status is "Completed"

      property :callback_url, type: :string
      # Type: String
      # Description: valid URI for callbacks

      property :callback_method, type: :string
      # Type: String
      # Description: GET or POST

      def_delegators :filters, :year, :month, :did_number, :year=, :month=, :did_number=

      def initialize(params = {})
        super params.reverse_merge(filters: {})
      end

      def csv
        return unless url.present?
        Down::Http.new(headers: { 'Api-Key' => DIDWW::Client.api_key }).open(url)
      end

      def complete?
        status == STATUS_COMPLETED
      end
      alias_method :completed?, :complete?
    end
  end
end
