# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      # Inbound messages are delivered as an HTTP request. Query parameters, headers
      # and body may use the placeholders {SMS_TEXT}, {SMS_TEXT_BASE64_ENCODED},
      # {SMS_SRC_ADDR}, {SMS_DST_ADDR} and {SMS_TIME}.
      class HttpIn < Base
        HTTP_METHOD_GET = 'get'
        HTTP_METHOD_POST = 'post'
        HTTP_METHOD_PUT = 'put'

        HTTP_METHODS = [
          HTTP_METHOD_GET,
          HTTP_METHOD_POST,
          HTTP_METHOD_PUT
        ].freeze

        BODY_TYPE_JSON = 'json'
        BODY_TYPE_HTML_MULTIPART = 'html_multipart'
        BODY_TYPE_HTML_URL_ENCODED = 'html_url_encoded'
        BODY_TYPE_RAW = 'raw'

        BODY_TYPES = [
          BODY_TYPE_JSON,
          BODY_TYPE_HTML_MULTIPART,
          BODY_TYPE_HTML_URL_ENCODED,
          BODY_TYPE_RAW
        ].freeze

        def self.type
          'http_in'
        end

        property :url, type: :string
        # Type: String
        # Description: Endpoint the request is sent to. Required when the trunk is created.

        property :http_method, type: :string
        # Type: String
        # Description: One of HTTP_METHODS. Required when the trunk is created.

        property :query_parameters
        # Type: Hash
        # Nullable: Yes
        # Description: Query parameters added to the request

        property :headers, sensitive: true
        # Type: Hash
        # Nullable: Yes
        # Description: Headers added to the request. Redacted in #inspect, as they may carry credentials.

        property :body_type, type: :string
        # Type: String
        # Nullable: Yes
        # Description: One of BODY_TYPES. Required for post and put, refused for get.

        property :body
        # Type: String or Hash
        # Nullable: Yes
        # Description: Request body template: a JSON string for json, a Hash for the form
        #              encodings, a String for raw. Required for post and put, refused for get.

        property :follow_redirect, type: :boolean
        # Type: Boolean
        # Description: Follow 3xx responses

        property :validate_https_certificate, type: :boolean
        # Type: Boolean
        # Description: Reject an untrusted TLS certificate
      end
    end
  end
end
