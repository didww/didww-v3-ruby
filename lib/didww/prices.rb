# frozen_string_literal: true
require 'csv'
require 'zlib'
require 'didww/errors'
require 'didww/prices/price'
require 'didww/prices/voice_in_price'
require 'didww/prices/voice_out_price'
require 'didww/prices/sms_out_price'
require 'didww/prices/sms_in_price'
require 'didww/prices/lookup_result'
require 'didww/prices/price_file'
require 'didww/prices/service'

module DIDWW
  module Prices
    VOICE_IN_FILTERS = {
      required: %w[number],
      optional: %w[src_country_iso]
    }.freeze
    VOICE_OUT_FILTERS = {
      required: %w[number]
    }.freeze
    SMS_FILTERS = {
      any_of: %w[dst_number dst_country_iso]
    }.freeze
    SERVICES = {
      voice_in: {
        host: :voice_in,
        path_prefix: '',
        price_class: VoiceInPrice,
        lookup_filters: VOICE_IN_FILTERS
      },
      voice_out: {
        host: :voice_out,
        path_prefix: '',
        price_class: VoiceOutPrice,
        lookup_filters: VOICE_OUT_FILTERS
      },
      sms_out_a2p: {
        host: :sms,
        path_prefix: 'sms_out/a2p/',
        price_class: SmsOutPrice,
        lookup_filters: SMS_FILTERS
      },
      sms_out_p2p: {
        host: :sms,
        path_prefix: 'sms_out/p2p/',
        price_class: SmsOutPrice,
        lookup_filters: SMS_FILTERS
      },
      sms_out_otp: {
        host: :sms,
        path_prefix: 'sms_out/otp/',
        price_class: SmsOutPrice,
        lookup_filters: SMS_FILTERS
      },
      sms_in: {
        host: :sms,
        path_prefix: 'sms_in/',
        price_class: SmsInPrice,
        lookup_filters: SMS_FILTERS
      }
    }.freeze

    # DIDWW::Prices.voice_in, .voice_out, .sms_out_a2p, .sms_out_p2p, .sms_out_otp and .sms_in
    # @return [DIDWW::Prices::Service]
    SERVICES.each do |name, options|
      define_singleton_method(name) { |**overrides| Service.new(**options, **overrides) }
    end

    # Reads a downloaded price file, which stays gzipped on disk.
    # @param path [String,Pathname] path of a *.csv.gz price file
    # @yieldparam row [CSV::Row] one row, keyed by the header line
    # @return [Enumerator] when no block is given
    def self.each_row(path, &block)
      return enum_for(:each_row, path) unless block

      Zlib::GzipReader.open(path.to_s, encoding: Encoding::UTF_8) { |gzip| CSV.new(gzip, headers: true).each(&block) }
      nil
    end
  end
end
