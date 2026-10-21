# frozen_string_literal: true
module DIDWW
  module Resource
    # Deleting a group also deletes the trunks in it.
    class SmsTrunkGroup < Base
      has_many :sms_trunks, class_name: 'SmsTrunk'
      has_many :incoming_dids, class_name: 'Did'

      property :name, type: :string
      # Type: String
      # Description: Friendly name of the group. Required when the group is created.

      property :external_reference_id, type: :string
      # Type: String
      # Nullable: Yes
      # Description: Customer-supplied reference. Max 100 characters.

      property :created_at, type: :time
      # Type: DateTime
      # Description: Group created at DateTime. Read-only.

      property :updated_at, type: :time
      # Type: DateTime
      # Description: Group updated at DateTime. Read-only.

      def sms_trunks_count
        attributes[:meta]&.[](:sms_trunks_count)
      end
    end
  end
end
