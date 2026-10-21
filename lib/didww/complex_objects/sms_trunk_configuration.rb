# frozen_string_literal: true
require 'didww/complex_objects/sms_trunk_configurations/base'
require 'didww/complex_objects/sms_trunk_configurations/generic'
require 'didww/complex_objects/sms_trunk_configurations/sms_to_email'
require 'didww/complex_objects/sms_trunk_configurations/http_in'
require 'didww/complex_objects/sms_trunk_configurations/http_out'
require 'didww/complex_objects/sms_trunk_configurations/smpp_esme'
require 'didww/complex_objects/sms_trunk_configurations/smpp_smsc'

module DIDWW
  module ComplexObject
    module SmsTrunkConfiguration
      TYPE_CLASSES = [
        SmsToEmail,
        HttpIn,
        HttpOut,
        SmppEsme,
        SmppSmsc
      ].to_h { |klass| [klass.type, klass] }.freeze

      TYPES = TYPE_CLASSES.keys.freeze

      # Production accepts nyc and ams; the sandbox accepts nyc only.
      SERVER_LOCATION_NYC = 'nyc'
      SERVER_LOCATION_AMS = 'ams'

      SERVER_LOCATIONS = [
        SERVER_LOCATION_NYC,
        SERVER_LOCATION_AMS
      ].freeze
    end
  end
end
