# frozen_string_literal: true
require 'didww/jsonapi_middleware'

module DIDWW
  module Resource
    autoload :Balance, 'didww/resource/balance'
    autoload :CapacityPool, 'didww/resource/capacity_pool'
    autoload :Export, 'didww/resource/export'
    autoload :SharedCapacityGroup, 'didww/resource/shared_capacity_group'
    autoload :City, 'didww/resource/city'
    autoload :Country, 'didww/resource/country'
    autoload :DidGroupType, 'didww/resource/did_group_type'
    autoload :DidGroup, 'didww/resource/did_group'
    autoload :Did, 'didww/resource/did'
    autoload :Order, 'didww/resource/order'
    autoload :Pop, 'didww/resource/pop'
    autoload :QtyBasedPricing, 'didww/resource/qty_based_pricing'
    autoload :Region, 'didww/resource/region'
    autoload :StockKeepingUnit, 'didww/resource/stock_keeping_unit'
    autoload :VoiceInTrunkGroup, 'didww/resource/voice_in_trunk_group'
    autoload :VoiceInTrunk, 'didww/resource/voice_in_trunk'
    autoload :AvailableDid, 'didww/resource/available_did'
    autoload :DidReservation, 'didww/resource/did_reservation'
    autoload :AddressRequirement, 'didww/resource/address_requirement'
    autoload :ProofType, 'didww/resource/proof_type'
    autoload :SupportingDocumentTemplate, 'didww/resource/supporting_document_template'
    autoload :Identity, 'didww/resource/identity'
    autoload :Proof, 'didww/resource/proof'
    autoload :Address, 'didww/resource/address'
    autoload :PermanentSupportingDocument, 'didww/resource/permanent_supporting_document'
    autoload :EncryptedFile, 'didww/resource/encrypted_file'
    autoload :AddressVerification, 'didww/resource/address_verification'
    autoload :AddressRequirementValidation, 'didww/resource/address_requirement_validation'
    autoload :PublicKey, 'didww/resource/public_key'
    autoload :Area, 'didww/resource/area'
    autoload :VoiceOutTrunk, 'didww/resource/voice_out_trunk'
    autoload :VoiceOutTrunkRegenerateCredential, 'didww/resource/voice_out_trunk_regenerate_credential'
    autoload :NanpaPrefix, 'didww/resource/nanpa_prefix'
    autoload :DidHistory, 'didww/resource/did_history'
    autoload :EmergencyRequirement, 'didww/resource/emergency_requirement'
    autoload :EmergencyRequirementValidation, 'didww/resource/emergency_requirement_validation'
    autoload :EmergencyCallingService, 'didww/resource/emergency_calling_service'
    autoload :EmergencyVerification, 'didww/resource/emergency_verification'

    class Base < JsonApiClient::Resource
      def as_json_api(*args)
        serialize_complex_attributes(super(*args))
      end

      private

      def serialize_complex_attributes(hash)
        # Replace complex objects with their json_api representation
        attributes = hash[:attributes]
        hash[:attributes] = attributes.to_h do |k, v|
          if v.respond_to?(:as_json_api)
            [k, v.as_json_api]
          elsif v.is_a?(Array)
            [k, v.map { |i| i.respond_to?(:as_json_api) ? i.as_json_api : i }]
          else
            [k, v]
          end
        end.with_indifferent_access
        return hash
      end
    end
  end
end
