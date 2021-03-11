require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object/blank'
require 'json_api_client'

require 'didww/resources/base'

module DIDWW
  module Client
    BASE_URLS = {
      sandbox:    'https://sandbox-api.didww.com/v3/'         .freeze,
      production: 'https://api.didww.com/v3/'                 .freeze
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

      def trunk_groups
        Resource::TrunkGroup
      end

      def trunks
        Resource::Trunk
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
        require 'didww/resources/balance'
        require 'didww/resources/capacity_pool'
        require 'didww/resources/cdr_export'
        require 'didww/resources/shared_capacity_group'
        require 'didww/resources/city'
        require 'didww/resources/country'
        require 'didww/resources/did_group_type'
        require 'didww/resources/did_group'
        require 'didww/resources/did'
        require 'didww/resources/order'
        require 'didww/resources/pop'
        require 'didww/resources/qty_based_pricing'
        require 'didww/resources/region'
        require 'didww/resources/stock_keeping_unit'
        require 'didww/resources/trunk_group'
        require 'didww/resources/trunk'
        require 'didww/resources/available_did'
        require 'didww/resources/did_reservation'
        require 'didww/resources/requirement'
        require 'didww/resources/proof_type'
        require 'didww/resources/supporting_document_template'
        require 'didww/resources/identity'
        require 'didww/resources/proof'
        require 'didww/resources/address'
        require 'didww/resources/permanent_supporting_document'
        require 'didww/resources/encrypted_file'
        require 'didww/resources/address_verification'
      end

    end
  end
end
