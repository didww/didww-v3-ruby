# frozen_string_literal: true
module DIDWW
  module Resource
    class Trunk < Base
      module CONST
        # Allowed values for trunk.cli_format
        CLI_FORMAT_RAW     = 'raw'                           .freeze
        CLI_FORMAT_E164    = 'e164'                          .freeze
        CLI_FORMAT_LOCAL   = 'local'                         .freeze

        CLI_FORMATS = {
          CLI_FORMAT_RAW   => 'Raw'                          .freeze,
          CLI_FORMAT_E164  => 'E.164'                        .freeze,
          CLI_FORMAT_LOCAL => 'Local'                        .freeze
        }.freeze

        # Configuration types
        CONF_TYPE_SIP     = 'sip_configurations'             .freeze
        CONF_TYPE_H323    = 'h323_configurations'            .freeze
        CONF_TYPE_IAX2    = 'iax2_configurations'            .freeze
        CONF_TYPE_PSTN    = 'pstn_configurations'            .freeze

        CONF_TYPES = {
          CONF_TYPE_SIP   => 'SIP'                           .freeze,
          CONF_TYPE_H323  => 'H323'                          .freeze,
          CONF_TYPE_IAX2  => 'IAX2'                          .freeze,
          CONF_TYPE_PSTN  => 'PSTN'                          .freeze
        }.freeze

        CONF_TYPE_CLASSES = {
          CONF_TYPE_SIP   => DIDWW::ComplexObject::SipConfiguration,
          CONF_TYPE_H323  => DIDWW::ComplexObject::H323Configuration,
          CONF_TYPE_IAX2  => DIDWW::ComplexObject::Iax2Configuration,
          CONF_TYPE_PSTN  => DIDWW::ComplexObject::PstnConfiguration
        }.freeze

        def cli_format_human
          CLI_FORMATS[cli_format]
        end

        def configuration_type_human
          CONF_TYPES[configuration.type] if configuration
        end
      end
    end
  end
end
