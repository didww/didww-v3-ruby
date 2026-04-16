# frozen_string_literal: true
module DIDWW
  module Resource
    class VoiceInTrunkGroup < Base
      has_many :voice_in_trunks

      property :name, type: :string
      # Type: String
      # Description: Trunk Group name

      property :capacity_limit, type: :integer
      # Type: Integer
      # Description: maximum number of simultaneous calls for the trunk

      property :created_at, type: :time
      # Type: DateTime
      # Description: Trunk Group created at DateTime

      property :external_reference_id, type: :string
      # Type: String
      # Description: Customer-supplied reference. Max 100 characters. (API 2026-04-16)

      def trunks_count
        meta[:trunks_count]
      end
    end
  end
end
