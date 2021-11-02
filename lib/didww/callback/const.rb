# frozen_string_literal: true

module DIDWW
  module Callback
    module CONST
      CALLBACK_METHOD_POST = 'POST'
      CALLBACK_METHOD_GET = 'GET'
      CALLBACK_METHODS = [
                           CALLBACK_METHOD_GET,
                           CALLBACK_METHOD_POST
                         ].freeze
    end
  end
end
