# frozen_string_literal: true

module DIDWW
  module Callback
    module CONST
      CALLBACK_METHOD_POST = 'post'
      CALLBACK_METHOD_GET = 'get'
      CALLBACK_METHODS = [
                           CALLBACK_METHOD_GET,
                           CALLBACK_METHOD_POST
                         ].freeze
    end
  end
end
