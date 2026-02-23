# frozen_string_literal: true
module DIDWW
  module Resource
    class SharedCapacityGroup < Base
      has_one :capacity_pool, class_name: 'CapacityPool'

      has_many :dids, class_name: 'Did'

      property :name, type: :string
      # Type: String
      # Description: Shared capacity group name

      property :shared_channels_count, type: :integer
      # Type: Integer
      # Description: Channels count assigned to this Group and shared among its DIDs

      property :metered_channels_count, type: :integer
      # Type: Integer
      # Description: Maximum amount of Metered channels used by this Group DIDs

      property :created_at, type: :time
      # Type: DateTime
      # Description: Shared capacity group created at DateTime

    end
  end
end
