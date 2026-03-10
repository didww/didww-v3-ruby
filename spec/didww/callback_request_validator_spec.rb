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

  context 'with cross-SDK test vectors' do
    context 'sandbox callback' do
      let(:api_key) { 'SOMEAPIKEY' }
      let(:url) { 'http://example.com/callback.php?id=7ae7c48f-d48a-499f-9dc1-c9217014b457&reject_reason=&status=approved&type=address_verifications' }
      let(:payload) do
        {
          'status' => 'approved',
          'id' => '7ae7c48f-d48a-499f-9dc1-c9217014b457',
          'type' => 'address_verifications',
          'reject_reason' => ''
        }
      end
      let(:signature) { '18050028b6b22d0ed516706fba1c1af8d6a8f9d5' }

      it { is_expected.to eq(true) }
    end

    context 'valid request' do
      let(:api_key) { 'SOMEAPIKEY' }
      let(:url) { 'http://example.com/callbacks' }
      let(:payload) do
        {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        }
      end
      let(:signature) { 'fe99e416c3547f2f59002403ec856ea386d05b2f' }

      it { is_expected.to eq(true) }
    end

    context 'valid request with query and fragment' do
      let(:api_key) { 'OTHERAPIKEY' }
      let(:url) { 'http://example.com/callbacks?foo=bar#baz' }
      let(:payload) do
        {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        }
      end
      let(:signature) { '32754ba93ac1207e540c0cf90371e7786b3b1cde' }

      it { is_expected.to eq(true) }
    end

    context 'empty signature' do
      let(:api_key) { 'SOMEAPIKEY' }
      let(:url) { 'http://example.com/callbacks' }
      let(:payload) do
        {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        }
      end
      let(:signature) { '' }

      it { is_expected.to eq(false) }
    end

    context 'invalid signature' do
      let(:api_key) { 'SOMEAPIKEY' }
      let(:url) { 'http://example.com/callbacks' }
      let(:payload) do
        {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        }
      end
      let(:signature) { 'fbdb1d1b18aa6c08324b7d64b71fb76370690e1d' }

      it { is_expected.to eq(false) }
    end
  end

end
