# frozen_string_literal: true
RSpec.describe DIDWW::Callback::RequestValidator, '#validate' do
  subject do
    validator = DIDWW::Callback::RequestValidator.new(api_key)
    validator.validate(url, payload, signature)
  end

  let(:api_key) { SecureRandom.hex(16) }
  let(:url) { 'http://foo.com/bar' }
  let(:payload) { { foo: 'bar', baz: 1 } }

  context 'with valid signature' do
    let(:signature) do
      data = 'http://foo.com:80/bar' + payload.sort.join
      OpenSSL::HMAC.hexdigest(DIDWW::Callback::RequestValidator::DIGEST_ALGO, api_key, data)
    end

    it { is_expected.to eq(true) }

    context 'when url without scheme' do
      let(:url) { 'foo.com/bar' }

      it { is_expected.to eq(true) }
    end

  end

  context 'with signature from another request' do
    let(:signature) do
      another_payload = { foo: 'bar', baz: 2 }
      data = 'http://foo.com:80/bar' + another_payload.sort.join
      OpenSSL::HMAC.hexdigest(DIDWW::Callback::RequestValidator::DIGEST_ALGO, api_key, data)
    end

    it { is_expected.to eq(false) }
  end

  context 'with invalid signature' do
    let(:signature) { 'test123' }

    it { is_expected.to eq(false) }
  end

  context 'with nil signature' do
    let(:signature) { '' }

    it { is_expected.to eq(false) }
  end

  context 'with blank signature' do
    let(:signature) { '' }

    it { is_expected.to eq(false) }
  end

end
