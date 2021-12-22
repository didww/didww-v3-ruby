# frozen_string_literal: true

require 'didww/callback/const'

module DIDWW
  module Resource
    class VoiceOutTrunk < Base
      include DIDWW::Callback::CONST

      ON_CLI_MISMATCH_ACTION_REJECT_CALL = 'Reject call'
      ON_CLI_MISMATCH_ACTION_REPLACE_CLI = 'Replace CLI'
      ON_CLI_MISMATCH_ACTION_SEND_ORIGINAL_CLI = 'Send Original CLI'

      ON_CLI_MISMATCH_ACTIONS = [
                                  ON_CLI_MISMATCH_ACTION_REJECT_CALL,
                                  ON_CLI_MISMATCH_ACTION_REPLACE_CLI,
                                  ON_CLI_MISMATCH_ACTION_SEND_ORIGINAL_CLI
                                ].freeze

      DEFAULT_DST_ACTION_ALLOW_CALLS = 'Allow Calls'
      DEFAULT_DST_ACTION_REJECT_CALLS = 'Reject Calls'

      DEFAULT_DST_ACTIONS = [
                              DEFAULT_DST_ACTION_ALLOW_CALLS,
                              DEFAULT_DST_ACTION_REJECT_CALLS
                            ].freeze

      STATUS_ACTIVE = 'Active'
      STATUS_BLOCKED = 'Blocked'

      STATUSES = [
                   STATUS_ACTIVE,
                   STATUS_BLOCKED
                 ].freeze

      MEDIA_ENCRYPTION_MODE_DISABLE = 'Disable'
      MEDIA_ENCRYPTION_MODE_SRTP_SDES = 'SRTP SDES'
      MEDIA_ENCRYPTION_MODE_SRTP_DTLS = 'SRTP DTLS'
      MEDIA_ENCRYPTION_MODE_ZRTP = 'ZRTP'

      MEDIA_ENCRYPTION_MODES = [
                                 MEDIA_ENCRYPTION_MODE_DISABLE,
                                 MEDIA_ENCRYPTION_MODE_SRTP_SDES,
                                 MEDIA_ENCRYPTION_MODE_SRTP_DTLS,
                                 MEDIA_ENCRYPTION_MODE_ZRTP
                               ].freeze

      property :name, type: :string
      property :allowed_sip_ips, type: :ip_addresses
      property :on_cli_mismatch_action, type: :string
      property :capacity_limit, type: :integer
      property :username, type: :string
      property :password, type: :string
      property :created_at, type: :time
      property :allow_any_did_as_cli, type: :boolean
      property :status, type: :string
      property :threshold_reached, type: :boolean
      property :threshold_amount, type: :decimal
      property :default_dst_action, type: :string
      property :dst_prefixes, type: :strings
      property :media_encryption_mode, type: :string
      property :callback_url, type: :string
      property :force_symmetric_rtp, type: :boolean
      property :allowed_rtp_ips, type: :ip_addresses
      property :rtp_ips, type: :ip_addresses

      has_many :dids

      def regenerate_credentials
        resource = DIDWW::Resource::VoiceOutTrunkRegenerateCredential.new
        resource.relationships[:voice_out_trunk] = self
        resource.save
      end
    end
  end
end
