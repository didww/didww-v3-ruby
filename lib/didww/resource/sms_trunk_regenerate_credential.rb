# frozen_string_literal: true

module DIDWW
  module Resource
    # Rotates the generated credentials of an smpp_esme or http_out trunk.
    # The new credentials are read back from the trunk.
    class SmsTrunkRegenerateCredential < Base
      has_one :sms_trunk

      # The request declares no attributes; json_api_client would send "attributes": {}.
      def as_json_api(*)
        super.tap { |h| h.delete(:attributes) if h[:attributes].blank? }
      end
    end
  end
end
