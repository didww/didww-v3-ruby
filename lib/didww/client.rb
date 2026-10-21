# frozen_string_literal: true
require 'logger'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object/blank'
require 'json_api_client'

require 'didww/version'
require 'didww/resource/base'
require 'didww/auth/memory_store'
require 'didww/auth/token_provider'

module DIDWW
  module Client
    BASE_URLS = {
      sandbox: 'https://sandbox-api.didww.com/v3/'.freeze,
      production: 'https://api.didww.com/v3/'.freeze
    }.freeze
    AUTH_URLS = {
      sandbox: 'https://auth-sandbox.didww.com'.freeze,
      production: 'https://auth.didww.com'.freeze
    }.freeze
    PRICES_URLS = {
      voice_in: {
        sandbox: 'https://api-vin-sandbox.didww.com/v3/'.freeze,
        production: 'https://api-vin.didww.com/v3/'.freeze
      }.freeze,
      voice_out: {
        sandbox: 'https://api-vout-sandbox.didww.com/v3/'.freeze,
        production: 'https://api-vout.didww.com/v3/'.freeze
      }.freeze,
      sms: {
        sandbox: 'https://api-sms-sandbox.didww.com/v3/'.freeze,
        production: 'https://api-sms.didww.com/v3/'.freeze
      }.freeze
    }.freeze
    PRICES_URL_ENV = {
      voice_in: 'DIDWW_API_VIN_URL',
      voice_out: 'DIDWW_API_VOUT_URL',
      sms: 'DIDWW_API_SMS_URL'
    }.freeze
    # Token audiences are production hostnames in every environment.
    API_AUDIENCE = 'api.didww.com'
    PRICES_AUDIENCES = {
      voice_in: 'api-vin.didww.com',
      voice_out: 'api-vout.didww.com',
      sms: 'api-sms.didww.com'
    }.freeze
    SCOPES = %i[read full].freeze
    DEFAULT_MODE = :sandbox
    DEFAULT_API_VERSION = '2026-10-22'
    API_VERSION_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/
    API_VERSION_OVERRIDE_KEY = :didww_api_version

    mattr_accessor :api_key, :api_mode, :http_verbose, :api_version, :scope, :token_store, :token_provider, :logger,
                   :_customize_conn_block, :_customize_faraday_block
    self.api_version = DEFAULT_API_VERSION
    self.token_store = Auth::MemoryStore.new
    self.token_provider = Auth::TokenProvider.new
    self.logger = Logger.new($stderr, level: :warn)

    class << self
      def customize_connection(&block)
        self._customize_conn_block = block
      end

      # Applied to the token, prices, export download and file upload connections.
      def customize_faraday(&block)
        self._customize_faraday_block = block
      end

      def configure
        yield self if block_given?
        connect!
        require_didww_resources
        self
      end

      def api_mode
        @@api_mode || DEFAULT_MODE
      end

      def api_key
        @@api_key
      end

      def api_version
        Thread.current[API_VERSION_OVERRIDE_KEY] || @@api_version
      end

      def api_version=(value)
        @@api_version = validate_api_version!(value)
      end

      # The override is visible only to the calling thread.
      def with_api_version(api_version)
        previous_api_version = Thread.current[API_VERSION_OVERRIDE_KEY]
        Thread.current[API_VERSION_OVERRIDE_KEY] = validate_api_version!(api_version)
        yield
      ensure
        Thread.current[API_VERSION_OVERRIDE_KEY] = previous_api_version
      end

      def scope=(value)
        unless value.nil? || SCOPES.include?(value)
          raise ArgumentError.new("Scope should be nil or in #{SCOPES} (given '#{value}').")
        end
        @@scope = value
      end

      def api_base_url
        ENV['DIDWW_API_URL'].presence || BASE_URLS[api_mode]
      end

      def auth_base_url
        ENV['DIDWW_AUTH_URL'].presence || AUTH_URLS[api_mode]
      end

      # @param service [Symbol] :voice_in, :voice_out or :sms
      def prices_base_url(service)
        ENV[PRICES_URL_ENV.fetch(service)].presence || PRICES_URLS.fetch(service)[api_mode]
      end

      # @param service [Symbol] :voice_in, :voice_out or :sms
      def prices_audience(service)
        PRICES_AUDIENCES.fetch(service)
      end

      def http_verbose?
        ENV['HTTP_VERBOSE'] == 'true' || http_verbose
      end

      def balance
        Resource::Balance.all.first
      end

      RESOURCE_CLASSES = {
        capacity_pools: 'CapacityPool',
        exports: 'Export',
        shared_capacity_groups: 'SharedCapacityGroup',
        cities: 'City',
        countries: 'Country',
        did_groups: 'DidGroup',
        dids: 'Did',
        orders: 'Order',
        regions: 'Region',
        voice_in_trunk_groups: 'VoiceInTrunkGroup',
        voice_in_trunks: 'VoiceInTrunk',
        voice_out_trunks: 'VoiceOutTrunk',
        sms_trunks: 'SmsTrunk',
        sms_trunk_groups: 'SmsTrunkGroup',
        available_dids: 'AvailableDid',
        did_reservations: 'DidReservation',
        address_requirements: 'AddressRequirement',
        identities: 'Identity',
        proofs: 'Proof',
        addresses: 'Address',
        permanent_supporting_documents: 'PermanentSupportingDocument',
        encrypted_file: 'EncryptedFile',
        address_verifications: 'AddressVerification',
        address_requirement_validation: 'AddressRequirementValidation',
        areas: 'Area',
        proof_types: 'ProofType',
        supporting_document_templates: 'SupportingDocumentTemplate',
        public_keys: 'PublicKey',
        nanpa_prefixes: 'NanpaPrefix',
        did_history: 'DidHistory',
        emergency_requirements: 'EmergencyRequirement',
        emergency_requirement_validation: 'EmergencyRequirementValidation',
        emergency_calling_services: 'EmergencyCallingService',
        emergency_verifications: 'EmergencyVerification',
      }.freeze

      RESOURCE_CLASSES.each do |name, klass|
        define_method(name) { Resource.const_get(klass) }
      end

      def voice_in_prices
        DIDWW::Prices.voice_in
      end

      def voice_out_prices
        DIDWW::Prices.voice_out
      end

      def sms_out_a2p_prices
        DIDWW::Prices.sms_out_a2p
      end

      def sms_out_p2p_prices
        DIDWW::Prices.sms_out_p2p
      end

      def sms_out_otp_prices
        DIDWW::Prices.sms_out_otp
      end

      def sms_in_prices
        DIDWW::Prices.sms_in
      end

      def api_mode=(arg)
        unless BASE_URLS.keys.include?(arg)
          raise ArgumentError.new("Mode should be in #{BASE_URLS.keys} (given '#{arg}').")
        end
        @@api_mode = arg
      end

      private

      def validate_api_version!(value)
        unless value.is_a?(String) && API_VERSION_FORMAT.match?(value)
          raise ArgumentError.new("API version should be a date in YYYY-MM-DD format (given '#{value}').")
        end
        if value < DEFAULT_API_VERSION
          raise ArgumentError.new("API version #{value} is not supported by didww-v3 #{VERSION}, which starts at #{DEFAULT_API_VERSION}; use didww-v3 6.x for earlier API versions.")
        end
        value
      end

      def connect!
        DIDWW::Resource::Base.site = api_base_url
        DIDWW::Resource::Base.connection do |connection|
          connection.use Faraday::Response::Logger if http_verbose?
          connection.use DIDWW::JsonapiMiddleware
          connection.use DIDWW::Auth::BearerMiddleware, audience: API_AUDIENCE
          _customize_conn_block.call(connection) if _customize_conn_block
        end
        JsonApiClient::Paginating::Paginator.page_param = 'number'
        JsonApiClient::Paginating::Paginator.per_page_param = 'size'
      end

      def require_didww_resources
        require 'didww/resource/balance'
        require 'didww/resource/capacity_pool'
        require 'didww/resource/export'
        require 'didww/resource/shared_capacity_group'
        require 'didww/resource/city'
        require 'didww/resource/country'
        require 'didww/resource/did_group'
        require 'didww/resource/did'
        require 'didww/resource/order'
        require 'didww/resource/qty_based_pricing'
        require 'didww/resource/region'
        require 'didww/resource/stock_keeping_unit'
        require 'didww/resource/voice_in_trunk_group'
        require 'didww/resource/voice_in_trunk'
        require 'didww/resource/available_did'
        require 'didww/resource/did_reservation'
        require 'didww/resource/address_requirement' # NOSONAR
        require 'didww/resource/proof_type'
        require 'didww/resource/supporting_document_template'
        require 'didww/resource/identity'
        require 'didww/resource/proof'
        require 'didww/resource/address'
        require 'didww/resource/permanent_supporting_document'
        require 'didww/resource/encrypted_file'
        require 'didww/resource/address_verification'
        require 'didww/resource/address_requirement_validation' # NOSONAR
        require 'didww/resource/public_key'
        require 'didww/resource/area'
        require 'didww/resource/voice_out_trunk'
        require 'didww/resource/voice_out_trunk_regenerate_credential'
        require 'didww/resource/sms_trunk'
        require 'didww/resource/sms_trunk_group'
        require 'didww/resource/sms_trunk_regenerate_credential' # NOSONAR
        require 'didww/resource/nanpa_prefix'
        require 'didww/resource/did_history' # NOSONAR
        require 'didww/resource/emergency_requirement' # NOSONAR
        require 'didww/resource/emergency_requirement_validation' # NOSONAR
        require 'didww/resource/emergency_calling_service' # NOSONAR
        require 'didww/resource/emergency_verification' # NOSONAR
      end

    end
  end
end
