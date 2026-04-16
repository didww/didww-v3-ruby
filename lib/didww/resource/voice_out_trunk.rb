# frozen_string_literal: true

require 'didww/callback/const'
require 'didww/complex_objects/authentication_method'

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
      property :on_cli_mismatch_action, type: :string
      property :capacity_limit, type: :integer
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

      # Type: String
      # Description: Customer-supplied reference. Max 100 characters. (API 2026-04-16)
      property :external_reference_id, type: :string

      # Type: Boolean
      # Description: When true, all customer DIDs assigned to this trunk are considered
      # emergency-enabled. Cannot be combined with emergency_dids. (API 2026-04-16)
      property :emergency_enable_all, type: :boolean

      # Type: Integer
      # Description: Seconds of RTP inactivity before the trunk tears down the call.
      # (API 2026-04-16)
      property :rtp_timeout, type: :integer

      # Polymorphic authentication_method (2026-04-16). One of:
      #   - ip_only:             { allowed_sip_ips, tech_prefix }
      #   - credentials_and_ip:  { allowed_sip_ips, tech_prefix, username, password }
      #     (username/password are server-generated and returned in responses only)
      #   - twilio:              { twilio_account_sid }
      # Replaces the flat `allowed_sip_ips`, `username`, `password` attributes
      # that existed in API v3.4 and earlier.
      property :authentication_method, type: :authentication_method

      has_one :default_did, class_name: 'Did'
      has_many :dids

      def regenerate_credentials
        resource = DIDWW::Resource::VoiceOutTrunkRegenerateCredential.new
        resource.relationships[:voice_out_trunk] = self
        resource.save
      end
    end
  end
end
