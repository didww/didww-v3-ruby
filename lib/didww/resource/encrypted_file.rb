# frozen_string_literal: true
require 'faraday/multipart'

module DIDWW
  module Resource
    class EncryptedFile < Base
      class UploadError < StandardError
      end

      property :description, type: :string
      # Type: String
      # Description:

      property :expires_at, type: :time
      # Type: Time
      # Description:

      # @return [Faraday::Connection]
      def self.upload_connection
        Faraday.new(url: site) do |connection|
          connection.request :multipart
          connection.request :url_encoded
          connection.adapter Faraday.default_adapter
          connection.use DIDWW::BaseMiddleware
        end
      end

      # @param file [Rack::Multipart::UploadedFile,(#tempfile,#content_type,#original_filename)]
      # @param fingerprint [String] DIDWW::Encrypt#encryption_fingerprint
      # @param description [String,nil] optional description (defaults to file.original_filename)
      # @return [String] new resource id
      # @raise [DIDWW::Resource::EncryptedFile::UploadError]
      def self.upload_file(file, fingerprint, description: nil)
        payload = {
          encryption_fingerprint: fingerprint,
          file: Faraday::Multipart::FilePart.new(file.tempfile, file.content_type),
          description: description || file.original_filename
        }
        upload(payload)
      end

      # @param payload [Hash]
      #   encryption_fingerprint [String] DIDWW::Encrypt#encryption_fingerprint
      #   file [Faraday::UploadIO] upload io
      #   description [String,nil] optional description
      # @return [String] new resource id
      # @raise [DIDWW::Resource::EncryptedFile::UploadError]
      def self.upload(payload)
        connection = upload_connection
        response = connection.post('/v3/encrypted_files', encrypted_files: payload)
        if response.status == 201
          JSON.parse(response.body, symbolize_names: true).dig(:data, :id)
        else
          raise UploadError, "Code: #{response.status} #{response.body}"
        end
      end
    end
  end
end
