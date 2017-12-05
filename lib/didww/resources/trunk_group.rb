module DIDWW
  module Resource
    class TrunkGroup < Base
      has_many :trunks

      property :name, type: :string
      # Type: String
      # Description: Trunk Group name

      property :capacity_limit, type: :integer
      # Type: Integer
      # Description: maximum number of simultaneous calls for the trunk

      property :created_at, type: :time
      # Type: DateTime
      # Description: Trunk Group created at DateTime

      def trunks_count
        meta[:trunks_count]
      end
    end
  end
end
