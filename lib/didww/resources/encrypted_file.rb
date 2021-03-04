module DIDWW
  module Resource
    class EncryptedFile < Base
      property :description, type: :string
      # Type: String
      # Description:

      property :expire_at, type: :date
      # Type: Date
      # Description:

      # @return [Array<String>]
      def self.upload(files, fingerprint)
        conn = Faraday.new(url: 'http://127.0.0.1:4000') do |faraday|
          faraday.request :multipart #make sure this is set before url_encoded
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.use DIDWW::BaseMiddleware
        end

        payload = {
          encrypted_files: {
            encryption_fingerprint: fingerprint,
            items: files.map do |file|
              {
                file: Faraday::UploadIO.new(file.tempfile, file.content_type),
                description: file.original_filename
              }
            end
          }
        }

        response = conn.post('/v3/encrypted_files', payload)
        if response.status == 201
          JSON.parse(response.body, symbolize_names: true)[:ids]
        else
          raise "encrypted files: #{response.status} #{response.body}"
        end
      end
    end
  end
end
