# frozen_string_literal: true
require 'fileutils'
require 'json'
require 'pathname'
require 'securerandom'
require 'active_support/core_ext/object/blank'
require 'didww/errors'
require 'didww/http'
require 'didww/prices/lookup_result'
require 'didww/prices/price_file'

module DIDWW
  module Prices
    class Service
      JSON_API_MEDIA_TYPE = 'application/vnd.api+json'
      FILE_PATH = 'prices.csv.gz'
      LOOKUP_PATH = 'lookup/prices'
      PRICE_PLAN_NOT_ASSIGNED = 'price_plan_not_assigned'
      TRANSPORT_ERRORS = [
        Faraday::ConnectionFailed,
        Faraday::TimeoutError,
        Faraday::SSLError
      ].freeze
      MAX_UNAVAILABLE_RETRIES = 2
      MAX_RETRY_AFTER = 60
      ERROR_CLASSES = {
        400 => BadRequest,
        401 => NotAuthorized,
        403 => AccessDenied,
        406 => NotAcceptable,
        429 => TooManyRequests,
        503 => ServiceUnavailable
      }.freeze
      NOT_FOUND_ERROR_CLASSES = {
        'price_not_found' => PriceNotFound,
        PRICE_PLAN_NOT_ASSIGNED => PricePlanNotAssigned
      }.freeze

      # Streams a 200 body into the IO and keeps any other body for the error.
      # A failed write is kept too: the adapter reports it as a connection failure.
      class Sink
        attr_reader :bytes_written, :error_body, :write_error

        def initialize(io)
          @io = io
          @bytes_written = 0
          @error_body = +''
        end

        def to_proc
          proc do |chunk, received, env|
            if env.status == 200
              write(chunk)
            else
              @error_body.clear if received == chunk.bytesize
              @error_body << chunk
            end
          end
        end

        private

        def write(chunk)
          @bytes_written += @io.write(chunk)
        rescue StandardError => e
          @write_error = e
          raise
        end
      end
      private_constant :Sink

      attr_reader :host, :path_prefix, :price_class, :lookup_filters

      # @param host [Symbol] :voice_in, :voice_out or :sms
      # @param path_prefix [String] price domain path below /v3/, such as 'sms_out/a2p/'
      # @param price_class [Class] DIDWW::Prices::Price subclass of the lookup rows
      # @param lookup_filters [Hash] filter names under :required, :optional and :any_of
      # @param sleeper [#call] waits the Retry-After of a 503 on a price file
      def initialize(host:, path_prefix:, price_class:, lookup_filters:, sleeper: ->(seconds) { sleep(seconds) })
        @host = host
        @path_prefix = path_prefix
        @price_class = price_class
        @lookup_filters = lookup_filters
        @sleeper = sleeper
      end

      # @param filters [Hash] lookup filters, such as number: '18005550123'
      # @return [DIDWW::Prices::LookupResult]
      # @raise [ArgumentError] a filter is missing or not allowed
      # @raise [DIDWW::Prices::Error]
      def lookup(**filters)
        filters = filters.transform_keys(&:to_s).reject { |_name, value| value.blank? }.transform_values(&:to_s)
        validate_filters!(filters)
        response = transport! { connection.get(lookup_path, { 'filter' => filters }, 'Accept' => JSON_API_MEDIA_TYPE) }
        raise_error!(response, response.body) unless response.status == 200

        LookupResult.from_json_api(JSON.parse(response.body), price_class)
      end

      # @param if_modified_since [Time,String,nil] Last-Modified of the copy held
      # @return [DIDWW::Prices::PriceFile]
      # @raise [DIDWW::Prices::Error]
      def head(if_modified_since: nil)
        PriceFile.from_response(file_request!(:head, if_modified_since))
      end

      # Writes the gzipped file unchanged. A path is written through a temp file next to it and
      # replaced only on 200, so a 304 or an error leaves an existing file as it was. The new
      # file gets the Last-Modified of the response as its modification time.
      # @param to [IO,String,Pathname] binary IO or file path
      # @param if_modified_since [Time,String,nil] Last-Modified of the copy held
      # @return [DIDWW::Prices::PriceFile]
      # @raise [DIDWW::Prices::Error]
      def download(to:, if_modified_since: nil)
        if to.is_a?(String) || to.is_a?(Pathname)
          download_to_path!(to.to_s, if_modified_since)
        else
          download_to_io!(to, if_modified_since)
        end
      end

      # Downloads the file to path unless the copy there is current: the modification time of
      # the file at path is sent as If-Modified-Since.
      # @param path [String,Pathname]
      # @return [DIDWW::Prices::PriceFile]
      # @raise [DIDWW::Prices::Error]
      def fetch(path)
        path = path.to_s
        if_modified_since = File.mtime(path) if File.exist?(path)
        download_to_path!(path, if_modified_since)
      end

      def file_path
        "#{path_prefix}#{FILE_PATH}"
      end

      def lookup_path
        "#{path_prefix}#{LOOKUP_PATH}"
      end

      private

      def connection
        DIDWW::Http.connection(
          "#{DIDWW::Client.prices_base_url(host).chomp('/')}/",
          audience: DIDWW::Client.prices_audience(host)
        )
      end

      def validate_filters!(filters)
        allowed = lookup_filters.values.flatten
        unknown = filters.keys - allowed
        missing = lookup_filters.fetch(:required, []) - filters.keys
        any_of = lookup_filters.fetch(:any_of, [])
        if unknown.any?
          raise ArgumentError.new("Filter #{unknown.join(', ')} is not allowed on #{lookup_path} (allowed: #{allowed.join(', ')}).")
        elsif missing.any?
          raise ArgumentError.new("Filter #{missing.join(', ')} is required on #{lookup_path}.")
        elsif any_of.any? && (any_of & filters.keys).empty?
          raise ArgumentError.new("One of filters #{any_of.join(', ')} is required on #{lookup_path}.")
        end
      end

      def download_to_io!(io, if_modified_since)
        sink = Sink.new(io)
        PriceFile.from_response(file_request!(:get, if_modified_since, sink), bytes_written: sink.bytes_written)
      end

      def download_to_path!(path, if_modified_since)
        tmp_path = "#{path}.#{SecureRandom.hex(8)}.tmp"
        price_file = File.open(tmp_path, 'wbx') do |file|
          download_to_io!(file, if_modified_since)
        end
        if price_file.modified?
          File.utime(price_file.last_modified, price_file.last_modified, tmp_path) if price_file.last_modified
          File.rename(tmp_path, path)
        end
        price_file
      ensure
        FileUtils.rm_f(tmp_path)
      end

      def file_request!(method, if_modified_since, sink = nil, attempt = 1)
        response = transport!(sink) do
          connection.run_request(method, file_path, nil, file_headers(if_modified_since)) do |request|
            request.options.on_data = sink.to_proc if sink
          end
        end
        retry_after = retry_after(response)
        if [200, 304].include?(response.status)
          response
        elsif response.status == 503 && attempt <= MAX_UNAVAILABLE_RETRIES && retry_after && retry_after <= MAX_RETRY_AFTER
          @sleeper.call(retry_after)
          file_request!(method, if_modified_since, sink, attempt + 1)
        else
          raise_error!(response, sink ? sink.error_body : response.body)
        end
      end

      def transport!(sink = nil)
        yield
      rescue *TRANSPORT_ERRORS => e
        raise sink.write_error if sink&.write_error

        raise ConnectionError.new(e.message)
      end

      def file_headers(if_modified_since)
        if if_modified_since
          { 'If-Modified-Since' => if_modified_since.respond_to?(:httpdate) ? if_modified_since.httpdate : if_modified_since.to_s }
        else
          {}
        end
      end

      def raise_error!(response, body)
        errors = parse_errors(body)
        code = errors.first&.fetch('code', nil)
        if response.status == 404
          code ||= PRICE_PLAN_NOT_ASSIGNED
          error_class = NOT_FOUND_ERROR_CLASSES.fetch(code, PricePlanNotAssigned)
        else
          error_class = ERROR_CLASSES.fetch(response.status, UnexpectedStatus)
        end
        raise error_class.new(status: response.status, code: code, errors: errors, retry_after: retry_after(response))
      end

      def parse_errors(body)
        document = JSON.parse(body.to_s)
        document.is_a?(Hash) ? Array(document['errors']).grep(Hash) : []
      rescue JSON::ParserError
        []
      end

      def retry_after(response)
        Integer(response.headers['Retry-After'], exception: false)
      end
    end
  end
end
