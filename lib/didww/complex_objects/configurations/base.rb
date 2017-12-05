require 'didww/complex_objects/configurations/const'

module DIDWW
  module ComplexObject
    module Configuration
      class Base < ComplexObject::Base
        include CONST
      end
    end
  end
end
