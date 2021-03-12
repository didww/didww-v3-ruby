# frozen_string_literal: true
require 'didww/complex_objects/configurations'
require 'didww/resources/trunk/const'

module DIDWW
  module Resource
    class Trunk < Base
      include CONST

      has_one :pop
      has_one :trunk_group

      property :priority, type: :integer
      # Type: Integer
      # Description: The priority of this target host. DIDWW will attempt to contact the target trunk with the lowest-numbered priority; target trunk with the same priority will be tried in an order defined by the weight field. The range is 0-65535. See RFC 2782 for more details

      property :weight, type: :integer
      # Type: Integer
      # Description: A trunk selection mechanism. The weight field specifies a relative weight for entries with the same priority. Larger weights will be given a proportionately higher probability of being selected. The range of this number is 0-65535. In the presence of records containing weights greater than 0, records with weight 0 will have a very small chance of being selected. See RFC 2782 for more details

      property :capacity_limit, type: :integer
      # Type: Integer
      # Description: Maximum number of simultaneous calls for the trunk

      property :ringing_timeout, type: :integer
      # Type: Integer
      # Description: After which it will be end transaction with internal disconnect code 'Ringing timeout' if the call was not connected.

      property :name, type: :string
      # Type: String
      # Description: Friendly name of the trunk

      property :cli_format, type: :string
      # Type: String
      # Description:
      # RAW - Do not alter CLI (default)
      # 164 - Attempt to convert CLI to E.164 format
      # Local - Attempt to convert CLI to Localized format
      # * CLI format conversion may not work correctly for phone calls originating from outside the country of that specific DID

      property :cli_prefix, type: :string
      # Type: String
      # Description: You may prefix the CLI with an optional '+' sign followed by up to 6 characters, including digits and '#'

      property :description, type: :string
      # Type: String
      # Description: Optional description of trunk

      property :configuration, type: :complex_object
      # Type: one of
      # sip_configurations
      # pstn_configurations
      # iax2_configurations
      # h323_configurations
      # Description: Trunk configuration complex object

      property :created_at, type: :time
      # Type: DateTime
      # Description: Trunk created at DateTime

      def initialize(*args)
        super
        attribute_will_change!(:configuration) if configuration
      end

    end
  end
end
