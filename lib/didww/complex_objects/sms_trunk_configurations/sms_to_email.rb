# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      # Inbound messages are forwarded as email.
      # send_to, subject and message are required when the trunk is created.
      class SmsToEmail < Base
        def self.type
          'sms_to_email'
        end

        property :send_to, type: :string
        # Type: String
        # Description: Recipient address

        property :subject, type: :string
        # Type: String
        # Description: Subject template

        property :message, type: :string
        # Type: String
        # Description: Body template
      end
    end
  end
end
