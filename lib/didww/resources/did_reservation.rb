module DIDWW
  module Resource
    class DidReservation < Base
      has_one :available_did

      property :expire_at, type: :time
      # Type: DateTime
      # Description: DateTime when the DID reservation expired or will expire. DateTime is in the ISO 8601 format "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", where "SSS" are milliseconds and 'Z' denotes Zulu time (UTC).

      property :created_at, type: :time
      # Type: DateTime
      # Description: DID reservation created at DateTime.

    end
  end
end
