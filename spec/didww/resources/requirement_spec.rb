# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Requirement do
  let (:client) { DIDWW::Client }

  describe 'GET /requirements/:id' do
    let(:id) { 'bf22f685-c036-49d9-b3ee-d5e6092f472e' }

    context 'when requirement exists' do
      let (:requirement) do
        stub_didww_request(:get, "/requirements/#{id}").to_return(
          status: 200,
          body: api_fixture('requirements/id/get/sample_1/200'),
          headers: json_api_headers
        )
        client.requirements.find(id).first
      end

      it 'returns a single Requirement' do
        expect(requirement).to be_kind_of(DIDWW::Resource::Requirement)
        expect(requirement.id).to eq(id)
      end

      describe 'has correct attributes' do
        it '"identity_type", type: Integer' do
          expect(requirement.identity_type).to be_kind_of(Integer)
        end

        it '"personal_area_level", type: String' do
          expect(requirement.personal_area_level).to be_kind_of(String)
        end

        it '"business_area_level", type: String' do
          expect(requirement.business_area_level).to be_kind_of(String)
        end

        it '"address_area_level", type: String' do
          expect(requirement.address_area_level).to be_kind_of(String)
        end

        it '"personal_proof_qty", type: Integer' do
          expect(requirement.personal_proof_qty).to be_kind_of(Integer)
        end

        it '"business_proof_qty", type: Integer' do
          expect(requirement.business_proof_qty).to be_kind_of(Integer)
        end

        it '"address_proof_qty", type: Integer' do
          expect(requirement.address_proof_qty).to be_kind_of(Integer)
        end

        it '"personal_mandatory_fields", type: String[]' do
          expect(requirement.personal_mandatory_fields).to match_array(be_kind_of(String)).or be_nil
        end

        it '"business_mandatory_fields", type: String[]' do
          expect(requirement.business_mandatory_fields).to match_array(be_kind_of(String)).or be_nil
        end

        it '"service_description_required", type: Boolean' do
          expect(requirement.service_description_required).to be_in([true, false])
        end

        it '"restriction_message", type: String' do
          expect(requirement.restriction_message).to be_kind_of(String)
        end
      end

      it 'lazily fetches Country' do
        request = stub_request(:get, requirement.relationships.country[:links][:related]).to_return(
          status: 200,
          body: api_fixture('countries/id/get/sample_1/200'),
          headers: json_api_headers
        )
        expect(requirement.country).to be_kind_of(DIDWW::Resource::Country)
        expect(request).to have_been_made.once
      end

      it 'lazily fetches DidGroupType' do
        request = stub_request(:get, requirement.relationships.did_group_type[:links][:related]).to_return(
          status: 200,
          body: api_fixture('did_group_types/id/get/sample_1/200'),
          headers: json_api_headers
        )
        expect(requirement.did_group_type).to be_kind_of(DIDWW::Resource::DidGroupType)
        expect(request).to have_been_made.once
      end

      it 'lazily fetches SupportingDocumentTemplate' do
        request = stub_request(:get, requirement.relationships.personal_permanent_document[:links][:related]).to_return(
          status: 200,
          body: api_fixture('supporting_document_templates/id/get/200'),
          headers: json_api_headers
        )
        expect(requirement.personal_permanent_document).to be_kind_of(DIDWW::Resource::SupportingDocumentTemplate)
        expect(request).to have_been_made.once
      end

      it 'lazily fetches ProofType' do
        request = stub_request(:get, requirement.relationships.personal_proof_types[:links][:related]).to_return(
          status: 200,
          body: api_fixture('proof_types/id/get/200'),
          headers: json_api_headers
        )
        expect(requirement.personal_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
        expect(request).to have_been_made.once
      end
    end

    context 'when Requirements does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/requirements/#{id}").to_return(
          status: 404,
          body: api_fixture('requirements/id/get/sample_1/404'),
          headers: json_api_headers
        )
        expect { client.requirements.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    it 'optionally includes Country, Did group type, Supporting documents and Proof types' do
      path_with_included = "/requirements/#{id}?include=country,did_group_type,personal_permanent_document,business_permanent_document,personal_onetime_document,business_onetime_document,personal_proof_types,business_proof_types,address_proof_types"
      stub_didww_request(:get, path_with_included).to_return(
        status: 200,
        body: api_fixture('requirements/id/get/sample_2/200'),
        headers: json_api_headers
      )
      requirement = client.requirements.includes(
        :country,
        :did_group_type,
        :personal_permanent_document,
        :business_permanent_document,
        :personal_onetime_document,
        :business_onetime_document,
        :personal_proof_types,
        :business_proof_types,
        :address_proof_types
      ).find(id).first

      expect(requirement.country).to be_an_instance_of(DIDWW::Resource::Country)
      expect(requirement.did_group_type).to be_an_instance_of(DIDWW::Resource::DidGroupType)
      expect(requirement.personal_permanent_document).to eq nil
      expect(requirement.business_permanent_document).to eq nil
      expect(requirement.personal_onetime_document).to eq nil
      expect(requirement.business_onetime_document).to eq nil
      expect(requirement.personal_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
      expect(requirement.business_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
      expect(requirement.address_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
    end
  end

  describe 'GET /requirements' do
    it 'returns a collection of Requirements' do
      stub_didww_request(:get, '/requirements').to_return(
        status: 200,
        body: api_fixture('requirements/get/sample_1/200'),
        headers: json_api_headers
      )
      expect(client.requirements.all).to all be_an_instance_of(DIDWW::Resource::Requirement)
    end

    it 'optionally includes Country, Did group type, Supporting documents and Proof types' do
      path_with_included = '/requirements?include=country,did_group_type,personal_permanent_document,business_permanent_document,personal_onetime_document,business_onetime_document,personal_proof_types,business_proof_types,address_proof_types'
      stub_didww_request(:get, path_with_included).to_return(
        status: 200,
        body: api_fixture('requirements/get/sample_2/200'),
        headers: json_api_headers
      )
      requirements = client.requirements.includes(
        :country,
        :did_group_type,
        :personal_permanent_document,
        :business_permanent_document,
        :personal_onetime_document,
        :business_onetime_document,
        :personal_proof_types,
        :business_proof_types,
        :address_proof_types
      ).all

      expect(requirements.first.country).to be_an_instance_of(DIDWW::Resource::Country)
      expect(requirements.first.did_group_type).to be_an_instance_of(DIDWW::Resource::DidGroupType)
      expect(requirements.first.personal_permanent_document).to eq nil
      expect(requirements.first.business_permanent_document).to eq nil
      expect(requirements.first.personal_onetime_document).to eq nil
      expect(requirements.first.business_onetime_document).to eq nil
      expect(requirements.first.personal_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
      expect(requirements.first.business_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
      expect(requirements.first.address_proof_types).to all be_an_instance_of(DIDWW::Resource::ProofType)
    end
  end
end
