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

        property :auth_password, type: :string
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
        # Description: Use RTP PING when connecting a call. After establishing the call, DIDWW will send empty RTP packet "RTP PING". It is neccessary if both parties operate in Symmetric RTP / Comedia mode and expect the other party to start sending RTP first.

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
        # Description: The transport layer that will be responsible for the actual transmission of SIP requests and responses (1 - UDP, 2 - TCP)

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
            codec_ids: DEFAULT_CODEC_IDS,
            rerouting_disconnect_code_ids: DEFAULT_REROUTING_DISCONNECT_CODE_IDS,
            transport_protocol_id: 1
        }.freeze

        RECOMMENDED = DEFAULTS.merge({
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
        }).freeze

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
      end
    end
  end
end
