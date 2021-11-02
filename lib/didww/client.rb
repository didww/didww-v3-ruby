# frozen_string_literal: true
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object/blank'
require 'json_api_client'

require 'didww/resource/base'

module DIDWW
  module Client
    BASE_URLS = {
      sandbox:    'https://sandbox-api.didww.com/v3/'         .freeze,
      production: 'https://sandbox-api.didww.com/v3/'                 .freeze
    }.freeze
    DEFAULT_MODE = :sandbox

    mattr_accessor :api_key, :api_mode, :http_verbose, :api_version

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

      def capacity_pools
        Resource::CapacityPool
      end

      def cdr_exports
        Resource::CdrExport
      end

      def shared_capacity_groups
        Resource::SharedCapacityGroup
      end

      def cities
        Resource::City
      end

      def countries
        Resource::Country
      end

      def did_group_types
        Resource::DidGroupType
      end

      def did_groups
        Resource::DidGroup
      end

      def dids
        Resource::Did
      end

      def orders
        Resource::Order
      end

      def pops
        Resource::Pop
      end

      def regions
        Resource::Region
      end

      def voice_in_trunk_groups
        Resource::VoiceInTrunkGroup
      end

      def voice_in_trunks
        Resource::VoiceInTrunk
      end

      def voice_out_trunks
        Resource::VoiceOutTrunk
      end

      def available_dids
        Resource::AvailableDid
      end

      def did_reservations
        Resource::DidReservation
      end

      def requirements
        Resource::Requirement
      end

      def identities
        Resource::Identity
      end

      def proofs
        Resource::Proof
      end

      def addresses
        Resource::Address
      end

      def permanent_supporting_documents
        Resource::PermanentSupportingDocument
      end

      def encrypted_file
        Resource::EncryptedFile
      end

      def address_verifications
        Resource::AddressVerification
      end

      def requirement_validation
        Resource::RequirementValidation
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
        require 'didww/resource/cdr_export'
        require 'didww/resource/shared_capacity_group'
        require 'didww/resource/city'
        require 'didww/resource/country'
        require 'didww/resource/did_group_type'
        require 'didww/resource/did_group'
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
      end

    end
  end
end
