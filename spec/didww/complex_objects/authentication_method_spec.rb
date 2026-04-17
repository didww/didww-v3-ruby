# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::AuthenticationMethod do
  let(:test_sip_ip) { '203.0.113.1/32' }

  describe 'polymorphic casting' do
    let(:base) { DIDWW::ComplexObject::AuthenticationMethod::Base }

    it 'casts ip_only to IpOnly subtype' do
      obj = base.cast({ type: 'ip_only', attributes: { allowed_sip_ips: [test_sip_ip], tech_prefix: '' } }, nil)
      expect(obj).to be_kind_of(DIDWW::ComplexObject::AuthenticationMethod::IpOnly)
      expect(obj.allowed_sip_ips).to eq([test_sip_ip])
      expect(obj.type).to eq('ip_only')
    end

    it 'casts credentials_and_ip to CredentialsAndIp subtype' do
      obj = base.cast({
        type: 'credentials_and_ip',
        attributes: {
          allowed_sip_ips: [test_sip_ip],
          username: 'u',
          password: 'p',
          tech_prefix: '9'
        }
      }, nil)
      expect(obj).to be_kind_of(DIDWW::ComplexObject::AuthenticationMethod::CredentialsAndIp)
      expect(obj.username).to eq('u')
      expect(obj.password).to eq('p')
      expect(obj.allowed_sip_ips).to eq([test_sip_ip])
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

  describe 'unknown type fallback (forward-compat)' do
    let(:base) { DIDWW::ComplexObject::AuthenticationMethod::Base }

    it 'wraps an unknown type in Generic instead of returning a raw Hash' do
      obj = base.cast(
        { type: 'future_auth_method',
          attributes: { some_new_field: 'value', another: 42 } },
        nil
      )
      expect(obj).to be_kind_of(DIDWW::ComplexObject::AuthenticationMethod::Generic)
      expect(obj).to be_kind_of(base)
    end

    it 'preserves the original type on Generic' do
      obj = base.cast(
        { type: 'future_auth_method', attributes: { some_new_field: 'value' } },
        nil
      )
      expect(obj.type).to eq('future_auth_method')
    end

    it 'preserves unknown attributes and round-trips through as_json' do
      obj = base.cast(
        { type: 'future_auth_method',
          attributes: { some_new_field: 'value', another: 42 } },
        nil
      )
      expect(obj.as_json).to eq(
        'type' => 'future_auth_method',
        'attributes' => { 'some_new_field' => 'value', 'another' => 42 }
      )
    end
  end

  describe '#as_json' do
    it 'serializes the singular type (not pluralized) for JSONAPI' do
      obj = DIDWW::ComplexObject::AuthenticationMethod::IpOnly.new(
        allowed_sip_ips: [test_sip_ip],
        tech_prefix: ''
      )
      expect(obj.as_json).to eq(
        'type' => 'ip_only',
        'attributes' => {
          'allowed_sip_ips' => [test_sip_ip],
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
