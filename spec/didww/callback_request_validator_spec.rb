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
    cross_sdk_vectors = [
      {
        name: 'sandbox callback',
        api_key: 'SOMEAPIKEY',
        url: 'http://example.com/callback.php?id=7ae7c48f-d48a-499f-9dc1-c9217014b457&reject_reason=&status=approved&type=address_verifications',
        payload: {
          'status' => 'approved',
          'id' => '7ae7c48f-d48a-499f-9dc1-c9217014b457',
          'type' => 'address_verifications',
          'reject_reason' => ''
        },
        signature: '18050028b6b22d0ed516706fba1c1af8d6a8f9d5',
        valid: true
      },
      {
        name: 'valid request',
        api_key: 'SOMEAPIKEY',
        url: 'http://example.com/callbacks',
        payload: {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        },
        signature: 'fe99e416c3547f2f59002403ec856ea386d05b2f',
        valid: true
      },
      {
        # Synthetic: URL fragments are never sent to the server in real HTTP requests.
        # Included to verify normalize_url handles fragments consistently across SDKs.
        name: 'valid request with query and fragment',
        api_key: 'OTHERAPIKEY',
        url: 'http://example.com/callbacks?foo=bar#baz',
        payload: {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        },
        signature: '32754ba93ac1207e540c0cf90371e7786b3b1cde',
        valid: true
      },
      {
        name: 'empty signature',
        api_key: 'SOMEAPIKEY',
        url: 'http://example.com/callbacks',
        payload: {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        },
        signature: '',
        valid: false
      },
      {
        name: 'invalid signature',
        api_key: 'SOMEAPIKEY',
        url: 'http://example.com/callbacks',
        payload: {
          'status' => 'completed',
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'type' => 'orders'
        },
        signature: 'fbdb1d1b18aa6c08324b7d64b71fb76370690e1d',
        valid: false
      },
      {
        # From the official DIDWW API documentation example:
        # https://doc.didww.com/api3/2022-05-10/callbacks-details.html#algorithm-implementation-details
        name: 'documentation example',
        api_key: 'szrdgh6547umt7tht7xbqhj6g9gdbyp7',
        url: 'https://mycompany.com/didww_callbacks?opaque=123',
        payload: {
          'id' => 'bf2cee72-6caa-4ae2-917e-bea01945691e',
          'status' => 'completed',
          'type' => 'orders'
        },
        signature: '30f66e9d72eb5e193051fd02952f70d8e934b4ff',
        valid: true
      }
    ].freeze

    cross_sdk_vectors.each do |vector|
      context vector[:name] do
        let(:api_key) { vector[:api_key] }
        let(:url) { vector[:url] }
        let(:payload) { vector[:payload] }
        let(:signature) { vector[:signature] }

        it { is_expected.to eq(vector[:valid]) }
      end
    end

    context 'URL normalization vectors' do
      let(:api_key) { 'SOMEAPIKEY' }
      let(:payload) do
        {
          'id' => '1dd7a68b-e235-402b-8912-fe73ee14243a',
          'status' => 'completed',
          'type' => 'orders'
        }
      end

      url_normalization_vectors = [
        { name: 'http://foo.com/bar', url: 'http://foo.com/bar', signature: '4d1ce2be656d20d064183bec2ab98a2ff3981f73' },
        { name: 'http://foo.com:80/bar (default HTTP port)', url: 'http://foo.com:80/bar', signature: '4d1ce2be656d20d064183bec2ab98a2ff3981f73' },
        { name: 'http://foo.com:443/bar (non-default port for HTTP)', url: 'http://foo.com:443/bar', signature: '904eaa65c0759afac0e4d8912de424e2dfb96ea1' },
        { name: 'http://foo.com:8182/bar (custom port)', url: 'http://foo.com:8182/bar', signature: 'eb8fcfb3d7ed4b4c2265d73cf93c31ba614384d1' },

        { name: 'http://foo.com/bar?baz=boo (with query string)', url: 'http://foo.com/bar?baz=boo', signature: '78b00717a86ce9df06abf45ff818aa94537e1729' },
        { name: 'http://user:pass@foo.com/bar (with userinfo)', url: 'http://user:pass@foo.com/bar', signature: '88615a11a78c021c1da2e1e0bfb8cc165170afc5' }, # NOSONAR
        # Synthetic: URL fragments are stripped by browsers/HTTP clients and never reach servers.
        # Included to verify normalize_url handles fragments consistently across SDKs.
        { name: 'http://foo.com/bar#test (with fragment)', url: 'http://foo.com/bar#test', signature: 'b1c4391fcdab7c0521bb5b9eb4f41f08529b8418' },
        { name: 'https://foo.com/bar', url: 'https://foo.com/bar', signature: 'f26a771c302319a7094accbe2989bad67fff2928' },
        { name: 'https://foo.com:443/bar (default HTTPS port)', url: 'https://foo.com:443/bar', signature: 'f26a771c302319a7094accbe2989bad67fff2928' },
        { name: 'https://foo.com:80/bar (non-default port for HTTPS)', url: 'https://foo.com:80/bar', signature: 'bd45af5253b72f6383c6af7dc75250f12b73a4e1' },
        { name: 'https://foo.com:8384/bar (custom port)', url: 'https://foo.com:8384/bar', signature: '9c9fec4b7ebd6e1c461cb8e4ffe4f2987a19a5d3' },
        { name: 'https://foo.com/bar?qwe=asd (with query string)', url: 'https://foo.com/bar?qwe=asd', signature: '4a0e98ddf286acadd1d5be1b0ed85a4e541c3137' },
        { name: 'https://qwe:asd@foo.com/bar (with userinfo)', url: 'https://qwe:asd@foo.com/bar', signature: '7a8cd4a6c349910dfecaf9807e56a63787250bbd' }, # NOSONAR
        # Synthetic: same as above, fragments are not part of real HTTP requests.
        { name: 'https://foo.com/bar#baz (with fragment)', url: 'https://foo.com/bar#baz', signature: '5024919770ea5ca2e3ccc07cb940323d79819508' },

        { name: 'http://[::1]/bar (ipv6 http default port)', url: 'http://[::1]/bar', signature: 'e0e9b83e4046d097f54b3ae64b08cbb4a539f601' },
        { name: 'http://[::1]:80/bar (ipv6 http explicit port 80)', url: 'http://[::1]:80/bar', signature: 'e0e9b83e4046d097f54b3ae64b08cbb4a539f601' },
        { name: 'http://[::1]:9090/bar (ipv6 http custom port)', url: 'http://[::1]:9090/bar', signature: 'ebec110ec5debd0e0fd086ff2f02e48ca665b543' },
        { name: 'https://[::1]/bar (ipv6 https default port)', url: 'https://[::1]/bar', signature: 'f3cfe6f523fdf1d4eaadc310fcd3ed92e1e324b0' },
        { name: 'http://foo.com/hello%20world (percent-encoded path)', url: 'http://foo.com/hello%20world', signature: 'eb64035b2e8f356ff1442898a39ec94d5c3e2fc8' },
        { name: 'http://foo.com/foo%2Fbar (percent-encoded slash in path)', url: 'http://foo.com/foo%2Fbar', signature: 'db24428442b012fa0972a453ba1ba98e755bba10' }
      ].freeze

      url_normalization_vectors.each do |vector|
        context vector[:name] do
          let(:url) { vector[:url] }
          let(:signature) { vector[:signature] }

          it { is_expected.to eq(true) }
        end
      end
    end
  end

end
