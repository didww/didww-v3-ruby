# frozen_string_literal: true
module DIDWW
  module Resource
    class EncryptedFile < Base
      class UploadError < StandardError
      end

      property :description, type: :string
      # Type: String
      # Description:

      property :expire_at, type: :date
      # Type: Date
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

      # @return [Array<String>]
      # @raise [DIDWW::Resource::EncryptedFile::UploadError]
      def self.upload(files, fingerprint)
        connection = upload_connection

        items = files.map do |file|
          {
            file: Faraday::UploadIO.new(file.tempfile, file.content_type),
            description: file.original_filename
          }
        end
        payload = {
          encrypted_files: {
            encryption_fingerprint: fingerprint,
            items: items
          }
        }

        response = connection.post('/v3/encrypted_files', payload)
        if response.status == 201
          JSON.parse(response.body, symbolize_names: true)[:ids]
        else
          raise UploadError, "Code: #{response.status} #{response.body}"
        end
      end
    end
  end
end
