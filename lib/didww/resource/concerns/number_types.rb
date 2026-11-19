# frozen_string_literal: true

module DIDWW
  module Resource
    # Possible values for number_type
    module NumberTypes
      NUMBER_TYPE_LOCAL = 'local'
      NUMBER_TYPE_NATIONAL = 'national'
      NUMBER_TYPE_MOBILE = 'mobile'
      NUMBER_TYPE_TOLL_FREE = 'toll_free'
      NUMBER_TYPE_SHARED_COST = 'shared_cost'
      NUMBER_TYPE_GLOBAL = 'global'

      NUMBER_TYPES = [
        NUMBER_TYPE_LOCAL,
        NUMBER_TYPE_NATIONAL,
        NUMBER_TYPE_MOBILE,
        NUMBER_TYPE_TOLL_FREE,
        NUMBER_TYPE_SHARED_COST,
        NUMBER_TYPE_GLOBAL
      ].freeze
    end
  end
end
