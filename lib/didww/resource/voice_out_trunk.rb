# frozen_string_literal: true

require 'didww/callback/const'
require 'didww/complex_objects/authentication_method'
require 'didww/resource/concerns/has_status_helpers'

module DIDWW
  module Resource
    class VoiceOutTrunk < Base
      include DIDWW::Callback::CONST
      include HasStatusHelpers

      ON_CLI_MISMATCH_ACTION_REJECT_CALL = 'reject_call'
      # replace_cli and randomize_cli require account configuration
      ON_CLI_MISMATCH_ACTION_REPLACE_CLI = 'replace_cli'
      ON_CLI_MISMATCH_ACTION_RANDOMIZE_CLI = 'randomize_cli'
      ON_CLI_MISMATCH_ACTION_SEND_ORIGINAL_CLI = 'send_original_cli'

      ON_CLI_MISMATCH_ACTIONS = [
                                  ON_CLI_MISMATCH_ACTION_REJECT_CALL,
                                  ON_CLI_MISMATCH_ACTION_REPLACE_CLI,
                                  ON_CLI_MISMATCH_ACTION_RANDOMIZE_CLI,
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

      CODEC_TELEPHONE_EVENT = 'telephone_event'
      CODEC_G723 = 'g723'
      CODEC_G729 = 'g729'
      CODEC_PCMU = 'pcmu'
      CODEC_PCMA = 'pcma'
      CODEC_GSM = 'gsm'
      CODEC_G722 = 'g722'
      CODEC_OPUS = 'opus'
      CODEC_AMR = 'amr'
      CODEC_AMR_WB = 'amr_wb'

      CODECS = [
        CODEC_TELEPHONE_EVENT,
        CODEC_G723,
        CODEC_G729,
        CODEC_PCMU,
        CODEC_PCMA,
        CODEC_GSM,
        CODEC_G722,
        CODEC_OPUS,
        CODEC_AMR,
        CODEC_AMR_WB
      ].freeze

      ICE_MODE_DISABLED = 'disabled'
      ICE_MODE_ACCEPT = 'accept'
      ICE_MODE_INITIATE = 'initiate'

      ICE_MODES = [
        ICE_MODE_DISABLED,
        ICE_MODE_ACCEPT,
        ICE_MODE_INITIATE
      ].freeze

      RTCP_MUX_MODE_DISABLED = 'disabled'
      RTCP_MUX_MODE_ACCEPT = 'accept'
      RTCP_MUX_MODE_INITIATE = 'initiate'

      RTCP_MUX_MODES = [
        RTCP_MUX_MODE_DISABLED,
        RTCP_MUX_MODE_ACCEPT,
        RTCP_MUX_MODE_INITIATE
      ].freeze

      RTCP_FEEDBACK_MODE_DISABLED = 'disabled'
      RTCP_FEEDBACK_MODE_ACCEPT = 'accept'
      RTCP_FEEDBACK_MODE_INITIATE = 'initiate'

      RTCP_FEEDBACK_MODES = [
        RTCP_FEEDBACK_MODE_DISABLED,
        RTCP_FEEDBACK_MODE_ACCEPT,
        RTCP_FEEDBACK_MODE_INITIATE
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
      property :rtp_ping, type: :boolean
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

      # Type: Array of strings
      # Description: Codecs offered on calls from the trunk, in priority order: the first has the
      # highest priority. One or more of CODECS. Defaults to pcma, pcmu, telephone_event.
      property :codecs, type: :strings

      # Type: String
      # Description: ICE (Interactive Connectivity Establishment) for calls from the trunk,
      # one of ICE_MODES. Defaults to accept.
      property :ice_mode, type: :string

      # Type: String
      # Description: RTP and RTCP multiplexed on one port, one of RTCP_MUX_MODES. Defaults to accept.
      property :rtcp_mux_mode, type: :string

      # Type: String
      # Description: RTCP feedback (AVPF), one of RTCP_FEEDBACK_MODES. Defaults to accept.
      property :rtcp_feedback_mode, type: :string

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
      has_many :emergency_dids, class_name: 'Did'

      status_helper :active, STATUS_ACTIVE
      status_helper :blocked, STATUS_BLOCKED

      def regenerate_credentials
        resource = DIDWW::Resource::VoiceOutTrunkRegenerateCredential.new
        resource.relationships[:voice_out_trunk] = self
        resource.save
      end
    end
  end
end
