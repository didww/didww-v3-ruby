# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module AuthenticationMethod
      class Twilio < Base
        def self.type
          'twilio'
        end

        property :twilio_account_sid, type: :string
      end
    end
  end
end
