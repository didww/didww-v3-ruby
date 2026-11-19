# frozen_string_literal: true

module DIDWW
  module Prices
    class LookupResult
      include Enumerable

      attr_reader :total_records

      # @param document [Hash] parsed JSON:API collection document
      # @param price_class [Class] DIDWW::Prices::Price subclass of the rows
      # @return [DIDWW::Prices::LookupResult]
      def self.from_json_api(document, price_class)
        new(
          document.fetch('data').map { |data| price_class.from_json_api(data) },
          total_records: document.dig('meta', 'total_records')
        )
      end

      def initialize(prices, total_records:)
        @prices = prices
        @total_records = total_records
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        @prices.each(&block)
        self
      end

      def size
        @prices.size
      end
    end
  end
end
