# frozen_string_literal: true

module DIDWW
  module Resource
    # Customer-owned subscription to emergency calling on one or more DIDs.
    # Supported operations: index, show, destroy. Introduced in API 2026-04-16.
    #
    # Server-side filters: name, reference, country.id, did_group_type.id,
    # address.id, identity.id, status.
    #
    # meta carries: setup_price, monthly_price.
    class EmergencyCallingService < Base
      STATUSES = [
        'active',
        'canceled',
        'changes required',
        'in process',
        'new',
        'pending update'
      ].freeze

      has_one :country, class_name: 'Country'
      has_one :did_group_type, class_name: 'DidGroupType'
      has_one :order, class_name: 'Order'
      has_one :address, class_name: 'Address'
      has_one :emergency_requirement, class_name: 'EmergencyRequirement'
      has_one :emergency_verification, class_name: 'EmergencyVerification'
      has_many :dids, class_name: 'Did'

      property :name, type: :string
      property :reference, type: :string
      property :status, type: :string
      property :activated_at, type: :time
      property :canceled_at, type: :time
      property :created_at, type: :time
      property :renew_date, type: :time
    end
  end
end
