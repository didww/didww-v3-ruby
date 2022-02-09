# frozen_string_literal: true

require 'didww/callback/const'

module DIDWW
  module Resource
    class VoiceOutTrunkRegenerateCredential < Base
      has_one :voice_out_trunk
    end
  end
end
