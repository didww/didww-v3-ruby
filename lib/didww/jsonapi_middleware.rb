# frozen_string_literal: true
require 'didww/base_middleware'
module DIDWW
  # :nodoc:
  class JsonapiMiddleware < BaseMiddleware
    private

    def request_headers(request_env)
      super.tap { |h| h['Content-Type'] = 'application/vnd.api+json' }
    end
  end
end
