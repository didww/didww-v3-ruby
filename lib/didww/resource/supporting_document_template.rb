# frozen_string_literal: true
module DIDWW
  module Resource
    class SupportingDocumentTemplate < Base
      property :name, type: :string
      # Type: String
      # Description:

      property :url, type: :string
      # Type: String
      # Description:

      property :permanent, type: :boolean
      # Type: Boolean
      # Description: whether the document template is permanent
    end
  end
end
