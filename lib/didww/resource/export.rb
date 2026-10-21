# frozen_string_literal: true
require 'forwardable'
require 'didww/resource/concerns/has_status_helpers'
require 'tempfile'
require 'zlib'
require 'stringio'
require 'didww/callback/const'

module DIDWW
  module Resource
    class Export < Base
      include DIDWW::Callback::CONST
      include HasStatusHelpers
      extend Forwardable

      STATUS_PENDING = 'pending'
      STATUS_PROCESSING = 'processing'
      STATUS_COMPLETED = 'completed'

      STATUSES = [
        STATUS_PENDING,
        STATUS_PROCESSING,
        STATUS_COMPLETED
      ].freeze

      EXPORT_TYPE_CDR_IN = 'cdr_in'
      EXPORT_TYPE_CDR_OUT = 'cdr_out'
      EXPORT_TYPE_SMS_IN = 'sms_in'
      EXPORT_TYPE_SMS_OUT = 'sms_out'
      EXPORT_TYPES = [
        EXPORT_TYPE_CDR_IN,
        EXPORT_TYPE_CDR_OUT,
        EXPORT_TYPE_SMS_IN,
        EXPORT_TYPE_SMS_OUT
      ].freeze

      property :filters, type: :export_filters
      # Type: Export Filters Object
      # Nullable: No
      # Description: Filters; the accepted keys depend on export_type (see ComplexObject::ExportFilters)

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

      property :export_type, type: :string
      # Type: String
      # Description: One of EXPORT_TYPES

      property :external_reference_id, type: :string
      # Type: String
      # Description: Customer-supplied reference. Max 100 characters. (API 2026-04-16)

      def initialize(params = {})
        super params.reverse_merge(filters: {})
      end

      # @return [Tempfile,nil] the gzipped CSV, rewound and opened in binary mode
      # @raise [JsonApiClient::Errors::ApiError]
      def download
        return unless url.present?
        file = Tempfile.new(['export', '.csv.gz'], binmode: true)
        response = download_connection.get do |request|
          request.options.on_data = proc { |chunk, _received, env| file.write(chunk) if env.status == 200 }
        end
        raise JsonApiClient::Errors::UnexpectedStatus.new(response.status, url) unless response.status == 200

        file.rewind
        file
      rescue StandardError
        file&.close!
        raise
      end

      def csv
        file = download
        return unless file
        begin
          gz = Zlib::GzipReader.new(file)
          StringIO.new(gz.read)
        ensure
          gz.close if gz && !gz.closed?
          file.close!
        end
      end

      status_helper :pending, STATUS_PENDING
      status_helper :processing, STATUS_PROCESSING
      status_helper :complete, STATUS_COMPLETED
      alias_method :completed?, :complete?

      private

      def download_connection
        DIDWW::Http.connection(url, audience: DIDWW::Client::API_AUDIENCE) do |connection|
          connection.use JsonApiClient::Middleware::Status, {}
        end
      end
    end
  end
end
