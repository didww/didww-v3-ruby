# frozen_string_literal: true
RSpec.describe DIDWW::ComplexObject::SmsTrunkConfiguration do
  let(:base) { DIDWW::ComplexObject::SmsTrunkConfiguration::Base }

  it 'exposes TYPES' do
    expect(described_class::TYPES).to eq(%w[sms_to_email http_in http_out smpp_esme smpp_smsc])
  end

  it 'exposes SERVER_LOCATIONS' do
    expect(described_class::SERVER_LOCATIONS).to eq(%w[nyc ams])
  end

  it 'exposes HTTP_METHODS and BODY_TYPES for http_in' do
    expect(described_class::HttpIn::HTTP_METHODS).to eq(%w[get post put])
    expect(described_class::HttpIn::BODY_TYPES).to eq(%w[json html_multipart html_url_encoded raw])
  end

  describe 'polymorphic casting' do
    {
      'sms_to_email' => DIDWW::ComplexObject::SmsTrunkConfiguration::SmsToEmail,
      'http_in' => DIDWW::ComplexObject::SmsTrunkConfiguration::HttpIn,
      'http_out' => DIDWW::ComplexObject::SmsTrunkConfiguration::HttpOut,
      'smpp_esme' => DIDWW::ComplexObject::SmsTrunkConfiguration::SmppEsme,
      'smpp_smsc' => DIDWW::ComplexObject::SmsTrunkConfiguration::SmppSmsc
    }.each do |type, klass|
      it "casts #{type} to #{klass.name.demodulize}" do
        obj = base.cast({ type: type, attributes: {} }, nil)
        expect(obj).to be_an_instance_of(klass)
        expect(obj.type).to eq(type)
      end
    end

    it 'casts typed attributes' do
      obj = base.cast(
        {
          type: 'smpp_smsc',
          attributes: {
            host: 'smsc.example.com',
            tx_port: '2775',
            transceiver_mode: true,
            server_location: 'nyc'
          }
        },
        nil
      )
      expect(obj.host).to eq('smsc.example.com')
      expect(obj.tx_port).to eq(2775)
      expect(obj.transceiver_mode).to eq(true)
      expect(obj.server_location).to eq(described_class::SERVER_LOCATION_NYC)
    end

    it 'keeps an http_in body given as a Hash' do
      obj = base.cast(
        { type: 'http_in', attributes: { body_type: 'html_url_encoded', body: { text: '{SMS_TEXT}' } } },
        nil
      )
      expect(obj.body).to eq('text' => '{SMS_TEXT}')
    end
  end

  describe 'unknown type fallback' do
    let(:obj) { base.cast({ type: 'future_sms_type', attributes: { some_new_field: 'value', another: 42 } }, nil) }

    it 'wraps an unknown type in Generic' do
      expect(obj).to be_an_instance_of(described_class::Generic)
      expect(obj).to be_kind_of(base)
    end

    it 'preserves the type and attributes through as_json' do
      expect(obj.as_json).to eq(
        'type' => 'future_sms_type',
        'attributes' => { 'some_new_field' => 'value', 'another' => 42 }
      )
    end

    it 'does not resolve helper class names as types' do
      expect(base.cast({ type: 'generic', attributes: {} }, nil).type).to eq('generic')
      expect(base.cast({ type: 'base', attributes: {} }, nil)).to be_an_instance_of(described_class::Generic)
    end
  end

  describe '#as_json' do
    it 'serializes the wire type and writable attributes' do
      obj = described_class::SmsToEmail.new(send_to: 'sms@example.com', subject: 'Inbound SMS', message: 'Hi')
      expect(obj.as_json).to eq(
        'type' => 'sms_to_email',
        'attributes' => { 'send_to' => 'sms@example.com', 'subject' => 'Inbound SMS', 'message' => 'Hi' }
      )
    end

    it 'drops the generated http_out credentials' do
      obj = described_class::HttpOut.new(
        callback_url: 'https://example.com/sms/status',
        allowed_ips: ['203.0.113.10'],
        auth_name: 'generated-name',
        auth_password: 'generated-password'
      )
      expect(obj.as_json).to eq(
        'type' => 'http_out',
        'attributes' => { 'callback_url' => 'https://example.com/sms/status', 'allowed_ips' => ['203.0.113.10'] }
      )
    end

    it 'drops the generated smpp_esme credentials' do
      obj = described_class::SmppEsme.new(server_location: 'nyc', system_id: 'esme1234', password: 'gen12345')
      expect(obj.as_json).to eq('type' => 'smpp_esme', 'attributes' => { 'server_location' => 'nyc' })
    end

    it 'sends the writable smpp_smsc password' do
      obj = described_class::SmppSmsc.new(system_id: 'didww', password: 'secret')
      expect(obj.as_json).to eq('type' => 'smpp_smsc', 'attributes' => { 'system_id' => 'didww', 'password' => 'secret' })
    end
  end

  describe '#inspect' do
    it 'redacts passwords and generated usernames' do
      http_out = described_class::HttpOut.new(auth_name: 'generated-name', auth_password: 'generated-password').inspect
      expect(http_out).not_to include('generated-name')
      expect(http_out).not_to include('generated-password')
      smpp_esme = described_class::SmppEsme.new(system_id: 'esme1234', password: 'gen12345').inspect
      expect(smpp_esme).not_to include('esme1234')
      expect(smpp_esme).not_to include('gen12345')
      expect(described_class::SmppSmsc.new(password: 'secret').inspect).to include('password="[FILTERED]"')
    end

    it 'redacts the headers of an http_in configuration' do
      http_in = described_class::HttpIn.new(headers: { 'Authorization' => 'Bearer webhook-secret' }).inspect

      expect(http_in).not_to include('webhook-secret')
      expect(http_in).to include('headers="[FILTERED]"')
    end

    it 'redacts every value of an unknown configuration type' do
      generic = base.cast(
        {
          type: 'future_sms_type',
          attributes: {
            url: 'https://hooks.example.com/sms',
            password: 'future-secret',
            headers: { 'Authorization' => 'Bearer future-token' },
            note: nil
          }
        },
        nil
      )

      expect(generic.inspect).to eq(
        '#<DIDWW::ComplexObject::SmsTrunkConfiguration::Generic type="future_sms_type" ' \
        'url="[FILTERED]" password="[FILTERED]" headers="[FILTERED]" note=nil>'
      )
      expect(generic.as_json[:attributes]).to include('password' => 'future-secret', 'url' => 'https://hooks.example.com/sms')
    end
  end
end
