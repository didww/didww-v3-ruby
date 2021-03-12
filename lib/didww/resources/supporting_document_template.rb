# frozen_string_literal: true
module DIDWW
  module Resource
    class SupportingDocumentTemplate < Base
      property :name, type: :string
      # Type: String
      # Description:

      property :template_typem, type: :integer
      # Type: Integer
      # Description:

      property :url, type: :string
      # Type: String
      # Description:
    end
  end
end
