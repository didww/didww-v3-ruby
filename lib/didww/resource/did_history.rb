# frozen_string_literal: true

module DIDWW
  module Resource
    # Immutable ownership-history records for DIDs in the customer's account.
    # Introduced in API 2026-04-16. Records are retained for the last 90 days only.
    #
    # Available filters (server-side):
    #   did_number (eq), action (eq), method (eq),
    #   created_at_gteq, created_at_lteq
    class DidHistory < Base
      ACTION_ASSIGNED = 'assigned'
      ACTION_RENEWED = 'renewed'
      ACTION_CANCELED = 'canceled'
      ACTION_REMOVED = 'removed'
      ACTION_BILLING_CYCLES_COUNT_CHANGED = 'billing_cycles_count_changed'
      ACTION_RESTORED = 'restored'

      ACTIONS = [
        ACTION_ASSIGNED,
        ACTION_RENEWED,
        ACTION_CANCELED,
        ACTION_REMOVED,
        ACTION_BILLING_CYCLES_COUNT_CHANGED,
        ACTION_RESTORED
      ].freeze

      METHOD_SYSTEM = 'system'
      METHOD_API2 = 'api2'
      METHOD_API3 = 'api3'
      METHOD_STAFF = 'staff'
      METHOD_USER_PANEL = 'user_panel'

      METHODS = [
        METHOD_SYSTEM,
        METHOD_API2,
        METHOD_API3,
        METHOD_STAFF,
        METHOD_USER_PANEL
      ].freeze

      def self.table_name
        'did_history'
      end

      property :did_number, type: :string
      # Type: String
      # Description: The DID number as it appeared on the account at the time of the event.

      property :action, type: :string
      # Type: String
      # Description: The operation that happened to the DID. See ACTIONS for possible values.

      property :method, type: :string
      # Type: String
      # Description: The channel/actor that triggered the operation. See METHODS for possible values.

      property :created_at, type: :time
      # Type: DateTime
      # Description: When the event occurred.

      # Meta attributes (accessible via the JSON:API `meta` hash on the
      # returned resource, not declared as properties):
      #
      # meta[:from] / meta[:to]
      #   Type: Integer
      #   Presence: only when action == 'billing_cycles_count_changed'.
      #   Description: The previous (from) and new (to) billing_cycles_count
      #                values. Absent for every other action.
    end
  end
end
