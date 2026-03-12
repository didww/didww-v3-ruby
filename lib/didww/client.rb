# frozen_string_literal: true
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object/blank'
require 'json_api_client'

require 'didww/resource/base'

module DIDWW
  module Client
    BASE_URLS = {
      sandbox: 'https://sandbox-api.didww.com/v3/'.freeze,
      production: 'https://api.didww.com/v3/'.freeze
    }.freeze
    DEFAULT_MODE = :sandbox
    DEFAULT_API_VERSION = '2022-05-10'

    mattr_accessor :api_key, :api_mode, :http_verbose, :api_version
    self.api_version = DEFAULT_API_VERSION

    class << self
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
        @@api_version
      end

      def with_api_version(api_version)
        old_api_version = self.api_version
        self.api_version = api_version
        yield
      ensure
        self.api_version = old_api_version
      end

      def api_base_url
        ENV['DIDWW_API_URL'].presence || BASE_URLS[api_mode]
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
        did_group_types: 'DidGroupType',
        did_groups: 'DidGroup',
        dids: 'Did',
        orders: 'Order',
        pops: 'Pop',
        regions: 'Region',
        voice_in_trunk_groups: 'VoiceInTrunkGroup',
        voice_in_trunks: 'VoiceInTrunk',
        voice_out_trunks: 'VoiceOutTrunk',
        available_dids: 'AvailableDid',
        did_reservations: 'DidReservation',
        requirements: 'Requirement',
        identities: 'Identity',
        proofs: 'Proof',
        addresses: 'Address',
        permanent_supporting_documents: 'PermanentSupportingDocument',
        encrypted_file: 'EncryptedFile',
        address_verifications: 'AddressVerification',
        requirement_validation: 'RequirementValidation',
        areas: 'Area',
        proof_types: 'ProofType',
        supporting_document_templates: 'SupportingDocumentTemplate',
        public_keys: 'PublicKey',
        nanpa_prefixes: 'NanpaPrefix',
      }.freeze

      RESOURCE_CLASSES.each do |name, klass|
        define_method(name) { Resource.const_get(klass) }
      end

      def api_mode=(arg)
        unless BASE_URLS.keys.include?(arg)
          raise ArgumentError.new("Mode should be in #{BASE_URLS.keys} (given '#{arg}').")
        end
        @@api_mode = arg
      end

      private

      def http_verbose?
        ENV['HTTP_VERBOSE'] == 'true' || http_verbose
      end

      def connect!
        DIDWW::Resource::Base.site = api_base_url
        DIDWW::Resource::Base.connection do |connection|
          connection.use Faraday::Response::Logger if http_verbose?
          connection.use DIDWW::JsonapiMiddleware
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
        require 'didww/resource/did_group_type'
        require 'didww/resource/did_group'
        require 'didww/resource/exclusive_relationship'
        require 'didww/resource/did'
        require 'didww/resource/order'
        require 'didww/resource/pop'
        require 'didww/resource/qty_based_pricing'
        require 'didww/resource/region'
        require 'didww/resource/stock_keeping_unit'
        require 'didww/resource/voice_in_trunk_group'
        require 'didww/resource/voice_in_trunk'
        require 'didww/resource/available_did'
        require 'didww/resource/did_reservation'
        require 'didww/resource/requirement'
        require 'didww/resource/proof_type'
        require 'didww/resource/supporting_document_template'
        require 'didww/resource/identity'
        require 'didww/resource/proof'
        require 'didww/resource/address'
        require 'didww/resource/permanent_supporting_document'
        require 'didww/resource/encrypted_file'
        require 'didww/resource/address_verification'
        require 'didww/resource/requirement_validation'
        require 'didww/resource/public_key'
        require 'didww/resource/area'
        require 'didww/resource/voice_out_trunk'
        require 'didww/resource/voice_out_trunk_regenerate_credential'
        require 'didww/resource/nanpa_prefix'
      end

    end
  end
end
