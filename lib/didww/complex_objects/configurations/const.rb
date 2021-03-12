# frozen_string_literal: true
module DIDWW
  module ComplexObject
    module Configuration
      module CONST
        RX_DTMF_FORMATS = {
            1 => 'RFC 2833'                                  .freeze,
            2 => 'SIP INFO application/dtmf-relay OR application/dtmf'.freeze,
            3 => 'RFC 2833 OR SIP INFO'                      .freeze
        }.freeze

        TX_DTMF_FORMATS = {
            0 => 'Disable sending'                           .freeze,
            1 => 'RFC 2833'                                  .freeze,
            2 => 'SIP INFO application/dtmf-relay'           .freeze,
            4 => 'SIP INFO application/dtmf'                 .freeze
        }.freeze

        SST_REFRESH_METHODS = {
            1 => 'Invite'                                    .freeze,
            2 => 'Update'                                    .freeze,
            3 => 'Update fallback Invite'                    .freeze
        }.freeze

        TRANSPORT_PROTOCOLS = {
            1 => 'UDP'                                       .freeze,
            2 => 'TCP'                                       .freeze
        }.freeze

        REROUTING_DISCONNECT_CODES = {
            56   => '400 | Bad Request'                      .freeze,
            57   => '401 | Unauthorized'                     .freeze,
            58   => '402 | Payment Required'                 .freeze,
            59   => '403 | Forbidden'                        .freeze,
            60   => '404 | Not Found'                        .freeze,
            64   => '408 | Request Timeout'                  .freeze,
            65   => '409 | Conflict'                         .freeze,
            66   => '410 | Gone'                             .freeze,
            67   => '412 | Conditional Request Failed'       .freeze,
            68   => '413 | Request Entity Too Large'         .freeze,
            69   => '414 | Request-URI Too Long'             .freeze,
            70   => '415 | Unsupported Media Type'           .freeze,
            71   => '416 | Unsupported URI Scheme'           .freeze,
            72   => '417 | Unknown Resource-Priority'        .freeze,
            73   => '420 | Bad Extension'                    .freeze,
            74   => '421 | Extension Required'               .freeze,
            75   => '422 | Session Interval Too Small'       .freeze,
            76   => '423 | Interval Too Brief'               .freeze,
            77   => '424 | Bad Location Information'         .freeze,
            78   => '428 | Use Identity Header'              .freeze,
            79   => '429 | Provide Referrer Identity'        .freeze,
            80   => '433 | Anonymity Disallowed'             .freeze,
            81   => '436 | Bad Identity-Info'                .freeze,
            82   => '437 | Unsupported Certificate'          .freeze,
            83   => '438 | Invalid Identity Header'          .freeze,
            84   => '480 | Temporarily Unavailable'          .freeze,
            86   => '482 | Loop Detected'                    .freeze,
            87   => '483 | Too Many Hops'                    .freeze,
            88   => '484 | Address Incomplete'               .freeze,
            89   => '485 | Ambiguous'                        .freeze,
            90   => '486 | Busy Here'                        .freeze,
            91   => '487 | Request Terminated'               .freeze,
            92   => '488 | Not Acceptable Here'              .freeze,
            96   => '494 | Security Agreement Required'      .freeze,
            97   => '500 | Server Internal Error'            .freeze,
            98   => '501 | Not Implemented'                  .freeze,
            99   => '502 | Bad Gateway'                      .freeze,
            100  => '503 | Service Unavailable'              .freeze,
            101  => '504 | Server Time-out'                  .freeze,
            102  => '505 | Version Not Supported'            .freeze,
            103  => '513 | Message Too Large'                .freeze,
            104  => '580 | Precondition Failure'             .freeze,
            105  => '600 | Busy Everywhere'                  .freeze,
            106  => '603 | Decline'                          .freeze,
            107  => '604 | Does Not Exist Anywhere'          .freeze,
            108  => '606 | Not Acceptable'                   .freeze,
            1505 => 'Ringing timeout'                        .freeze
        }.freeze

        CODECS = {
            6  => 'telephone-event'                          .freeze,
            7  => 'G723'                                     .freeze,
            8  => 'G729'                                     .freeze,
            9  => 'PCMU'                                     .freeze,
            10 => 'PCMA'                                     .freeze,
            12 => 'speex'                                    .freeze,
            13 => 'GSM'                                      .freeze,
            14 => 'G726-32'                                  .freeze,
            15 => 'G721'                                     .freeze,
            16 => 'G726-24'                                  .freeze,
            17 => 'G726-40'                                  .freeze,
            18 => 'G726-16'                                  .freeze,
            19 => 'L16'                                      .freeze
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

        DEFAULT_CODEC_IDS = [ 9, 10, 8, 7, 6 ].freeze

        DID_PLACEHOLDER = '{DID}'.freeze
      end
    end
  end
end
