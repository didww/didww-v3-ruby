# frozen_string_literal: true

module DIDWW
  module ComplexObject
    module Configuration
      class Base < ComplexObject::Base
        RX_DTMF_FORMATS = {
                            1 => 'RFC 2833',
                            2 => 'SIP INFO application/dtmf-relay OR application/dtmf',
                            3 => 'RFC 2833 OR SIP INFO'
                          }.freeze

        TX_DTMF_FORMATS = {
                            0 => 'Disable sending',
                            1 => 'RFC 2833',
                            2 => 'SIP INFO application/dtmf-relay',
                            4 => 'SIP INFO application/dtmf'
                          }.freeze

        SST_REFRESH_METHODS = {
                                1 => 'Invite',
                                2 => 'Update',
                                3 => 'Update fallback Invite'
                              }.freeze

        TRANSPORT_PROTOCOLS = {
                                1 => 'UDP',
                                2 => 'TCP',
                                3 => 'TLS'
                              }.freeze

        REROUTING_DISCONNECT_CODES = {
                                       56 => '400 | Bad Request',
                                       57 => '401 | Unauthorized',
                                       58 => '402 | Payment Required',
                                       59 => '403 | Forbidden',
                                       60 => '404 | Not Found',
                                       64 => '408 | Request Timeout',
                                       65 => '409 | Conflict',
                                       66 => '410 | Gone',
                                       67 => '412 | Conditional Request Failed',
                                       68 => '413 | Request Entity Too Large',
                                       69 => '414 | Request-URI Too Long',
                                       70 => '415 | Unsupported Media Type',
                                       71 => '416 | Unsupported URI Scheme',
                                       72 => '417 | Unknown Resource-Priority',
                                       73 => '420 | Bad Extension',
                                       74 => '421 | Extension Required',
                                       75 => '422 | Session Interval Too Small',
                                       76 => '423 | Interval Too Brief',
                                       77 => '424 | Bad Location Information',
                                       78 => '428 | Use Identity Header',
                                       79 => '429 | Provide Referrer Identity',
                                       80 => '433 | Anonymity Disallowed',
                                       81 => '436 | Bad Identity-Info',
                                       82 => '437 | Unsupported Certificate',
                                       83 => '438 | Invalid Identity Header',
                                       84 => '480 | Temporarily Unavailable',
                                       86 => '482 | Loop Detected',
                                       87 => '483 | Too Many Hops',
                                       88 => '484 | Address Incomplete',
                                       89 => '485 | Ambiguous',
                                       90 => '486 | Busy Here',
                                       91 => '487 | Request Terminated',
                                       92 => '488 | Not Acceptable Here',
                                       96 => '494 | Security Agreement Required',
                                       97 => '500 | Server Internal Error',
                                       98 => '501 | Not Implemented',
                                       99 => '502 | Bad Gateway',
                                       100 => '503 | Service Unavailable',
                                       101 => '504 | Server Time-out',
                                       102 => '505 | Version Not Supported',
                                       103 => '513 | Message Too Large',
                                       104 => '580 | Precondition Failure',
                                       105 => '600 | Busy Everywhere',
                                       106 => '603 | Decline',
                                       107 => '604 | Does Not Exist Anywhere',
                                       108 => '606 | Not Acceptable',
                                       1505 => 'Ringing timeout'
                                     }.freeze

        CODECS = {
                   6 => 'telephone-event',
                   7 => 'G723',
                   8 => 'G729',
                   9 => 'PCMU',
                   10 => 'PCMA',
                   12 => 'speex',
                   13 => 'GSM',
                   14 => 'G726-32',
                   15 => 'G721',
                   16 => 'G726-24',
                   17 => 'G726-40',
                   18 => 'G726-16',
                   19 => 'L16'
                 }.freeze

        DEFAULT_REROUTING_DISCONNECT_CODE_IDS = [
                                                  56,
                                                  58,
                                                  59,
                                                  60,
                                                  64,
                                                  65,
                                                  66,
                                                  67,
                                                  68,
                                                  69,
                                                  70,
                                                  71,
                                                  72,
                                                  73,
                                                  74,
                                                  75,
                                                  76,
                                                  77,
                                                  78,
                                                  79,
                                                  80,
                                                  81,
                                                  82,
                                                  83,
                                                  84,
                                                  86,
                                                  87,
                                                  88,
                                                  89,
                                                  90,
                                                  91,
                                                  92,
                                                  96,
                                                  97,
                                                  98,
                                                  99,
                                                  101,
                                                  102,
                                                  103,
                                                  104,
                                                  105,
                                                  106,
                                                  107,
                                                  108,
                                                  1505
                                                ].freeze

        DEFAULT_CODEC_IDS = [9, 10, 8, 7, 6].freeze

        DID_PLACEHOLDER = '{DID}'
      end
    end
  end
end
