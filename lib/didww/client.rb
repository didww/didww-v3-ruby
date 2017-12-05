require 'active_support/core_ext/module/attribute_accessors'
require 'json_api_client'

require 'didww/resources/base'

module DIDWW
  module Client
    BASE_URLS = {
      sandbox:    'https://sandbox-api.didww.com/v3/'         .freeze,
      production: 'https://api.didww.com/v3/'                 .freeze
    }.freeze
    DEFAULT_MODE = :sandbox

    mattr_accessor :api_key, :api_mode, :http_verbose

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

      def api_base_url
        BASE_URLS[api_mode]
      end

      def balance
        Resource::Balance.all.first
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

      def regions
        Resource::Region
      end

      def trunk_groups
        Resource::TrunkGroup
      end

      def trunks
        Resource::Trunk
      end

      def cdr_exports
        Resource::CdrExport
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
          connection.use DIDWW::Middleware
        end
        JsonApiClient::Paginating::Paginator.page_param = 'number'
        JsonApiClient::Paginating::Paginator.per_page_param = 'size'
      end

      def require_didww_resources
        require 'didww/resources/balance'
        require 'didww/resources/city'
        require 'didww/resources/country'
        require 'didww/resources/did_group_type'
        require 'didww/resources/did_group'
        require 'didww/resources/did'
        require 'didww/resources/order'
        require 'didww/resources/region'
        require 'didww/resources/trunk_group'
        require 'didww/resources/trunk'
        require 'didww/resources/stock_keeping_unit'
        require 'didww/resources/cdr_export'
      end

    end
  end
end
