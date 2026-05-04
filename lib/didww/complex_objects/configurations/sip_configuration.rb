# frozen_string_literal: true
module DIDWW
  module ComplexObject
    module Configuration
      class SipConfiguration < Base
        property :username, type: :string
        # Type: String
        # Nullable: No
        # Description: User part of R-URI in INVITE request.You also may use "{DID}" pattern which will be replaced by called DID number in E164 format. For example, you can set Username to "+{DID}"; if you wish to have it in +E164 format

        property :host, type: :string
        # Type: String
        # Nullable: No
        # Description: Host part of R-URI in INVITE request

        property :auth_user, type: :string
        # Type: String
        # Nullable: No
        # Description: Optional authorization user for the SIP server

        property :auth_password, type: :string, sensitive: true
        # Type: String
        # Nullable: No
        # Description: Optional authorization password for the SIP server

        property :auth_from_user, type: :string
        # Type: String
        # Nullable: No
        # Description: Specify user in a "from" field instead of CallerID (overrides CallerID). Some equipment require "from"; to be equivalent to "Auth user";

        property :auth_from_domain, type: :string
        # Type: String
        # Nullable: No
        # Description: Sets default "from" domain in SIP messages. Some equipment may require specific "From" Domain

        property :sst_refresh_method_id, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: SIP method which will be used for session update.
        # See RFC 4028 for more details.
        # Possible values:
        # 1 - Invite
        # 2 - Update
        # 3 - Update fallback Invite

        property :sip_timer_b, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: INVITE transaction timeout (Default 8000ms). See RFC 3261 Section 17.1.1.2 for more details

        property :dns_srv_failover_timer, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: Invite transaction timeout for each of gateways with DNS SRV rerouting (Default 2000ms)

        property :rtp_ping, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Use RTP PING when connecting a call. After establishing the call, DIDWW will send empty RTP packet "RTP PING". It is necessary if both parties operate in Symmetric RTP / Comedia mode and expect the other party to start sending RTP first.

        property :rtp_timeout, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: Disconnect call if the RTP packets do not arrive within the specified time

        property :sst_min_timer, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: Minimal SIP Session timer value (Default 600 seconds). See RFC 4028 for more details

        property :sst_max_timer, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: Maximal SIP Session timer value (Default 900 seconds). See RFC 4028 for more details

        property :sst_session_expires, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: Session-Expires header value. Optional, should be in range sst_min_timer ... sst_max_timer.
        # See RFC 4028 for more details

        property :port, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: Port part of R-URI in INVITE request (is not mandatory).If port is null, SRV record will be resolved (or A record if SRV is unavailable)

        property :rx_dtmf_format_id, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: The method id for receiving DTMF signals from customer equipment
        # Possible values:
        # 1 - RFC 2833
        # 2 - SIP INFO application/dtmf-relay OR application/dtmf
        # 3 - RFC 2833 OR SIP INFO

        property :tx_dtmf_format_id, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: The method of sending DTMF signals to customer equipment
        # Possible values:
        # 1 - Disable sending
        # 2 - RFC 2833
        # 3 - SIP INFO application/dtmf-relay
        # 4 - SIP INFO application/dtmf

        property :force_symmetric_rtp, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Forced to work in Symmetric RTP / COMEDIA mode

        property :symmetric_rtp_ignore_rtcp, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Avoid switching RTP session based on RTCP packet while working in Symmetric RTP / COMEDIA. Only RTP packets will be considered

        property :sst_enabled, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Enable SIP Session timers customization. SIP session timers are used to make sure that a session (dialog) is still alive, even though there may have been a long time since the last in-dialog message. If the other end is not responding, the dialog will be hung up automatically. SIP session timers need to be supported by all end points for it to work. It's a SIP extension, standardized by the IETF. See RFC 4028 for more details

        property :sst_accept_501, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Do not drop the call after receiving SIP 501 response for non-critical messages

        property :auth_enabled, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Enable authorization for the SIP server

        property :resolve_ruri, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Replace host part of the R-URI by resolved IP address

        property :rerouting_disconnect_code_ids, type: :array
        # TODO array type
        # Type: Array
        # Nullable: No
        # Description: Rerouting disconnect codes

        property :codec_ids, type: :array
        # TODO array type
        # Type: Array
        # Nullable: No
        # Description: Codecs

        property :transport_protocol_id, type: :integer
        # Type: Integer
        # Nullable: No
        # Description: The transport layer that will be responsible for the actual transmission of SIP requests and responses. See TRANSPORT_PROTOCOLS for available values.

        property :max_transfers, type: :integer
        # Nullable: No
        # Description: Max count of the REFER requests

        property :max_30x_redirects, type: :integer
        # Nullable: No
        # Description: Max count of 301/302 redirects

        property :media_encryption_mode, type: :string
        # Type: String
        # Nullable: No
        # Description: The Media encryption mode for RTP traffic. See MEDIA_ENCRYPTION_MODES for available values.

        property :stir_shaken_mode, type: :string
        # Type: String
        # Nullable: No
        # Description: The STIR/SHAKEN mode for sending identity via SIP. See STIR_SHAKEN_MODES for available values.

        property :allowed_rtp_ips, type: :ip_addresses
        # Type: Array of strings
        # Nullable: Yes
        # Description: Allowed IP addresses for RTP connection.

        property :diversion_relay_policy, type: :string
        # Type: String
        # Nullable: No
        # Description: Diversion header relay policy for SIP INVITE.
        # See DIVERSION_RELAY_POLICIES for available values.
        # In API v3.4 this attribute was named `diversion_relay_mode`.

        property :diversion_inject_mode, type: :string
        # Type: String
        # Nullable: No
        # Description: Diversion header injection mode. See
        # DIVERSION_INJECT_MODES for available values. (API 2026-04-16)

        property :network_protocol_priority, type: :string
        # Type: String
        # Nullable: No
        # Description: SIP network protocol priority. See
        # NETWORK_PROTOCOL_PRIORITIES for available values. (API 2026-04-16)

        property :enabled_sip_registration, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Enables SIP registration. When true the API generates
        # `incoming_auth_username` / `incoming_auth_password`; the trunk's
        # `host` and `port` must be left blank. When disabling sip
        # registration on an existing trunk, the same PATCH must also set
        # `host` to a non-blank value and `use_did_in_ruri` to false, or
        # the server returns 422. (API 2026-04-16)

        property :use_did_in_ruri, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: When true, the trunk's R-URI uses the DID number.
        # Requires `enabled_sip_registration` to be true. (API 2026-04-16)

        property :cnam_lookup, type: :boolean
        # Type: Boolean
        # Nullable: No
        # Description: Enables CNAM resolution for inbound calls on this
        # trunk. (API 2026-04-16)

        property :incoming_auth_username, type: :string, read_only: true, sensitive: true
        # Type: String
        # Nullable: Yes
        # Description: Server-generated SIP authentication username, returned in
        #   responses when `enabled_sip_registration` is true. Read-only; the API
        #   rejects any write attempt with 400 Param not allowed. (API 2026-04-16)

        property :incoming_auth_password, type: :string, read_only: true, sensitive: true
        # Type: String
        # Nullable: Yes
        # Description: Server-generated SIP authentication password, returned in
        #   responses when `enabled_sip_registration` is true. Read-only; the API
        #   rejects any write attempt with 400 Param not allowed. (API 2026-04-16)

        DIVERSION_RELAY_POLICY_NONE = 'none'
        DIVERSION_RELAY_POLICY_AS_IS = 'as_is'
        DIVERSION_RELAY_POLICY_SIP = 'sip'
        DIVERSION_RELAY_POLICY_TEL = 'tel'

        DIVERSION_RELAY_POLICIES = [
          DIVERSION_RELAY_POLICY_NONE,
          DIVERSION_RELAY_POLICY_AS_IS,
          DIVERSION_RELAY_POLICY_SIP,
          DIVERSION_RELAY_POLICY_TEL
        ].freeze

        DIVERSION_INJECT_MODE_NONE = 'none'
        DIVERSION_INJECT_MODE_DID_NUMBER = 'did_number'

        DIVERSION_INJECT_MODES = [
          DIVERSION_INJECT_MODE_NONE,
          DIVERSION_INJECT_MODE_DID_NUMBER
        ].freeze

        NETWORK_PROTOCOL_PRIORITY_FORCE_IPV4 = 'force_ipv4'
        NETWORK_PROTOCOL_PRIORITY_FORCE_IPV6 = 'force_ipv6'
        NETWORK_PROTOCOL_PRIORITY_ANY = 'any'
        NETWORK_PROTOCOL_PRIORITY_PREFER_IPV4 = 'prefer_ipv4'
        NETWORK_PROTOCOL_PRIORITY_PREFER_IPV6 = 'prefer_ipv6'

        NETWORK_PROTOCOL_PRIORITIES = [
          NETWORK_PROTOCOL_PRIORITY_FORCE_IPV4,
          NETWORK_PROTOCOL_PRIORITY_FORCE_IPV6,
          NETWORK_PROTOCOL_PRIORITY_ANY,
          NETWORK_PROTOCOL_PRIORITY_PREFER_IPV4,
          NETWORK_PROTOCOL_PRIORITY_PREFER_IPV6
        ].freeze

        MEDIA_ENCRYPTION_MODES = [
                                   'disabled',
                                   'srtp_sdes',
                                   'srtp_dtls',
                                   'zrtp'
                                 ].freeze

        STIR_SHAKEN_MODES = [
                              'disabled',
                              'original',
                              'pai',
                              'original_pai',
                              'verstat'
                            ].freeze

        DEFAULTS = {
            username: DID_PLACEHOLDER,
            port: '5060',
            tx_dtmf_format_id: 1,
            sst_min_timer: 600,
            sst_max_timer: 900,
            sst_refresh_method_id: 1,
            sst_accept_501: true,
            sip_timer_b: 8000,
            dns_srv_failover_timer: 2000,
            rtp_timeout: 30,
            auth_enabled: false,
            max_transfers: 0,
            max_30x_redirects: 0,
            codec_ids: DEFAULT_CODEC_IDS,
            rerouting_disconnect_code_ids: DEFAULT_REROUTING_DISCONNECT_CODE_IDS,
            transport_protocol_id: 1
        }.freeze

        RECOMMENDED = DEFAULTS.merge(
            #-- Authentication
            auth_user: '',
            auth_password: '',
            auth_from_user: '',
            auth_from_domain: '',
            #-- Media & DTMF
            rx_dtmf_format_id: 1,
            rtp_ping: false,
            force_symmetric_rtp: false,
            symmetric_rtp_ignore_rtcp: false,
            #-- Advanced Signalling Settings
            sst_enabled: false,
            sst_session_expires: '',
        ).freeze

        def sst_refresh_method
          SST_REFRESH_METHODS[sst_refresh_method_id]
        end

        def rx_dtmf_format
          RX_DTMF_FORMATS[rx_dtmf_format_id]
        end

        def tx_dtmf_format
          TX_DTMF_FORMATS[tx_dtmf_format_id]
        end

        def transport_protocol
          TRANSPORT_PROTOCOLS[transport_protocol_id]
        end

        # Auto-cascade for server-enforced field dependencies (2026-04-16).
        #
        # The server validates these combinations and rejects mismatches with
        # 422; the SDK fixes them up at assignment time so user code never has
        # to track the full server-side rule set. Future server-required
        # cascades are added here without the caller needing to know.
        #
        # Rules:
        #   * `enabled_sip_registration = true`  => host = nil, port = nil
        #     (server requires both blank when registration is enabled)
        #   * `enabled_sip_registration = false` => use_did_in_ruri = false
        #     (server requires use_did_in_ruri disabled when sip_registration is)
        #   * `host = <non-nil>` => enabled_sip_registration = false,
        #     use_did_in_ruri = false (host requires sip_registration disabled,
        #     which in turn requires use_did_in_ruri disabled)
        #
        # Constructor-time `[]=` assignments bypass these setters intentionally
        # so that responses returned from the server (e.g. a fixture with
        # `enabled_sip_registration: true` AND `host: nil`) deserialize as-is.
        def enabled_sip_registration=(val)
          case val
          when true
            # Always emit host: null and port: null on the wire when
            # enabling sip_registration. The server requires both blank
            # (returns 422 otherwise) AND a PATCH against an existing
            # trunk that already has host/port set on the server side
            # MUST explicitly nullify them — the SDK's local attributes
            # hash starts empty, so there's nothing to "preserve".
            self[:host] = nil
            self[:port] = nil
          when false
            # Server requires use_did_in_ruri = false whenever sip_registration
            # is disabled. Always emit it on the wire so the server's check
            # passes regardless of the prior state of the field.
            self[:use_did_in_ruri] = false
          else
            # `nil` (or any non-bool) — caller is unsetting the field. No
            # cascade: dependent fields stay as the caller left them.
          end
          self[:enabled_sip_registration] = val
        end

        def host=(val)
          unless val.nil?
            # Setting host implies sip_registration is disabled (server-side
            # validation), which in turn implies use_did_in_ruri = false.
            # Always emit both on the wire so the server's checks pass
            # without the caller having to know the rule set.
            self[:enabled_sip_registration] = false
            self[:use_did_in_ruri] = false
          end
          self[:host] = val
        end
      end
    end
  end
end
