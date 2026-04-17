# frozen_string_literal: true

require 'didww/callback/const'

module DIDWW
  module Resource
    class VoiceOutTrunk < Base
      include DIDWW::Callback::CONST

      ON_CLI_MISMATCH_ACTION_REJECT_CALL = 'reject_call'
      ON_CLI_MISMATCH_ACTION_REPLACE_CLI = 'replace_cli'
      ON_CLI_MISMATCH_ACTION_SEND_ORIGINAL_CLI = 'send_original_cli'

      ON_CLI_MISMATCH_ACTIONS = [
                                  ON_CLI_MISMATCH_ACTION_REJECT_CALL,
                                  ON_CLI_MISMATCH_ACTION_REPLACE_CLI,
                                  ON_CLI_MISMATCH_ACTION_SEND_ORIGINAL_CLI
                                ].freeze

      DEFAULT_DST_ACTION_ALLOW_ALL = 'allow_all'
      DEFAULT_DST_ACTION_REJECT_ALL = 'reject_all'

      DEFAULT_DST_ACTIONS = [
                              DEFAULT_DST_ACTION_ALLOW_ALL,
                              DEFAULT_DST_ACTION_REJECT_ALL
                            ].freeze

      STATUS_ACTIVE = 'active'
      STATUS_BLOCKED = 'blocked'

      STATUSES = [
                   STATUS_ACTIVE,
                   STATUS_BLOCKED
                 ].freeze

      MEDIA_ENCRYPTION_MODE_DISABLED = 'disabled'
      MEDIA_ENCRYPTION_MODE_SRTP_SDES = 'srtp_sdes'
      MEDIA_ENCRYPTION_MODE_SRTP_DTLS = 'srtp_dtls'
      MEDIA_ENCRYPTION_MODE_ZRTP = 'zrtp'

      MEDIA_ENCRYPTION_MODES = [
                                 MEDIA_ENCRYPTION_MODE_DISABLED,
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

      has_many :dids

      def regenerate_credentials
        resource = DIDWW::Resource::VoiceOutTrunkRegenerateCredential.new
        resource.relationships[:voice_out_trunk] = self
        resource.save
      end
    end
  end
end
