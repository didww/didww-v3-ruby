# frozen_string_literal: true
RSpec.describe DIDWW::TooManyRequests do
  let(:client) { DIDWW::Client }
  let(:retry_after_headers) { {} }
  let(:too_many_requests_response) do
    {
      status: 429,
      body: '{"errors":[{"title":"Too many requests","code":"too_many_requests","status":"429"}]}',
      headers: json_api_headers.merge(retry_after_headers)
    }
  end

  it 'is the TooManyRequests error of json_api_client' do
    expect(described_class).to be < JsonApiClient::Errors::TooManyRequests
  end

  context 'when a read is answered 429' do
    let(:retry_after_headers) { { 'Retry-After' => '30' } }
    let!(:request) { stub_didww_request(:get, '/voice_in_trunks').to_return(too_many_requests_response) }

    it 'raises with the Retry-After seconds, without retrying' do
      expect { client.voice_in_trunks.all }.to raise_error(described_class, /Too many requests/) do |error|
        expect(error.retry_after).to eq(30)
      end
      expect(request).to have_been_made.once
    end
  end

  context 'when a write is answered 429' do
    let(:retry_after_headers) { { 'Retry-After' => '5' } }
    let!(:request) { stub_didww_request(:post, '/voice_in_trunk_groups').to_return(too_many_requests_response) }

    it 'raises with the Retry-After seconds, without retrying' do
      group = client.voice_in_trunk_groups.new(name: 'Office')

      expect { group.save }.to raise_error(described_class, /Too many requests/) do |error|
        expect(error.retry_after).to eq(5)
      end
      expect(request).to have_been_made.once
    end
  end

  context 'when Retry-After is missing' do
    let!(:request) { stub_didww_request(:get, '/voice_in_trunks').to_return(too_many_requests_response) }

    it 'has no retry_after' do
      expect { client.voice_in_trunks.all }.to raise_error(described_class) do |error|
        expect(error.retry_after).to be_nil
      end
      expect(request).to have_been_made.once
    end
  end

  context 'when Retry-After has a leading zero' do
    let(:retry_after_headers) { { 'Retry-After' => '010' } }
    let!(:request) { stub_didww_request(:get, '/voice_in_trunks').to_return(too_many_requests_response) }

    it 'reads it as decimal seconds' do
      expect { client.voice_in_trunks.all }.to raise_error(described_class) do |error|
        expect(error.retry_after).to eq(10)
      end
    end
  end

  context 'when Retry-After is not a number of seconds' do
    let(:retry_after_headers) { { 'Retry-After' => 'Wed, 11 Nov 2026 07:28:00 GMT' } }
    let!(:request) { stub_didww_request(:get, '/voice_in_trunks').to_return(too_many_requests_response) }

    it 'has no retry_after' do
      expect { client.voice_in_trunks.all }.to raise_error(described_class) do |error|
        expect(error.retry_after).to be_nil
      end
      expect(request).to have_been_made.once
    end
  end
end
