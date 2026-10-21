# frozen_string_literal: true
module DIDWW
  module Auth
    class MemoryStore
      # Any object responding to read(key), write(key, value, expires_in:) and
      # delete(key) can replace it, e.g. an ActiveSupport::Cache::Store.

      def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @clock = clock
        @lock = Mutex.new
        @entries = {}
      end

      def read(key)
        @lock.synchronize do
          value, expires_at = @entries[key]
          if expires_at && expires_at <= @clock.call
            @entries.delete(key)
            nil
          else
            value
          end
        end
      end

      def write(key, value, expires_in: nil)
        @lock.synchronize { @entries[key] = [value, expires_in && @clock.call + expires_in] }
        true
      end

      def delete(key)
        @lock.synchronize { !@entries.delete(key).nil? }
      end

      def inspect
        "#<#{self.class.name} entries=#{@lock.synchronize { @entries.size }}>"
      end
    end
  end
end
