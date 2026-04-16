# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::AuthenticationMethod do
  describe 'polymorphic casting' do
    let(:base) { DIDWW::ComplexObject::AuthenticationMethod::Base }

    it 'casts ip_only to IpOnly subtype' do
      obj = base.cast({ type: 'ip_only', attributes: { allowed_sip_ips: ['10.0.0.1/32'], tech_prefix: '' } }, nil)
      expect(obj).to be_kind_of(DIDWW::ComplexObject::AuthenticationMethod::IpOnly)
      expect(obj.allowed_sip_ips).to eq(['10.0.0.1/32'])
      expect(obj.type).to eq('ip_only')
    end

    it 'casts credentials_and_ip to CredentialsAndIp subtype' do
      obj = base.cast({
        type: 'credentials_and_ip',
        attributes: {
          allowed_sip_ips: ['10.0.0.1/32'],
          username: 'u',
          password: 'p',
          tech_prefix: '9'
        }
      }, nil)
      expect(obj).to be_kind_of(DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp)
      expect(obj.username).to eq('u')
      expect(obj.password).to eq('p')
      expect(obj.allowed_sip_ips).to eq(['10.0.0.1/32'])
      expect(obj.tech_prefix).to eq('9')
      expect(obj.type).to eq('credentials_and_ip')
    end

    it 'casts twilio to Twilio subtype' do
      obj = base.cast({ type: 'twilio', attributes: { twilio_account_sid: 'AC123' } }, nil)
      expect(obj).to be_kind_of(DIDWW::ComplexObject::AuthenticationMethod::Twilio)
      expect(obj.twilio_account_sid).to eq('AC123')
      expect(obj.type).to eq('twilio')
    end
  end

  describe '#as_json' do
    it 'serializes the singular type (not pluralized) for JSONAPI' do
      obj = DIDWW::ComplexObject::AuthenticationMethod::IpOnly.new(
        allowed_sip_ips: ['10.0.0.1/32'],
        tech_prefix: ''
      )
      expect(obj.as_json).to eq(
        'type' => 'ip_only',
        'attributes' => {
          'allowed_sip_ips' => ['10.0.0.1/32'],
          'tech_prefix' => ''
        }
      )
    end
  end

  describe 'TYPES constant' do
    it 'enumerates all three supported types' do
      expect(DIDWW::ComplexObject::AuthenticationMethod::TYPES).to contain_exactly(
        'ip_only', 'credentials_and_ip', 'twilio'
      )
    end
  end
end
