# frozen_string_literal: true
require 'time'

module DIDWW
  module Prices
    class PriceFile
      STATUS_OK = :ok
      STATUS_NOT_MODIFIED = :not_modified
      FILENAME_PATTERN = /filename="?([^";]+)"?/

      attr_reader :status, :last_modified, :content_length, :filename, :bytes_written

      # @param response [Faraday::Response] a 200 or 304 answer of GET or HEAD
      # @param bytes_written [Integer,nil] bytes of the file written by a download
      # @return [DIDWW::Prices::PriceFile]
      def self.from_response(response, bytes_written: nil)
        headers = response.headers
        new(
          status: response.status == 304 ? STATUS_NOT_MODIFIED : STATUS_OK,
          last_modified: parse_http_date(headers['Last-Modified']),
          content_length: headers['Content-Length']&.to_i,
          filename: headers['Content-Disposition'].to_s[FILENAME_PATTERN, 1],
          bytes_written: bytes_written
        )
      end

      def self.parse_http_date(value)
        Time.httpdate(value) if value
      rescue ArgumentError
        nil
      end

      def initialize(status:, last_modified: nil, content_length: nil, filename: nil, bytes_written: nil)
        @status = status
        @last_modified = last_modified
        @content_length = content_length
        @filename = filename
        @bytes_written = bytes_written
      end

      # The file changed after the If-Modified-Since date sent, or none was sent.
      def modified?
        status == STATUS_OK
      end

      def not_modified?
        status == STATUS_NOT_MODIFIED
      end
    end
  end
end
