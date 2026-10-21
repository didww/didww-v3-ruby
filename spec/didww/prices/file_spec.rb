# frozen_string_literal: true
require 'tmpdir'

RSpec.describe DIDWW::Prices::Service do
  subject(:service) { DIDWW::Prices.voice_in(sleeper: ->(seconds) { sleeps << seconds }) }

  let(:sleeps) { [] }
  let(:fixture_path) { 'spec/fixtures/prices/voice_in_prices.csv.gz' }
  let(:gzip_fixture) { File.binread(fixture_path) }
  let(:file_uri) { 'https://api-vin-sandbox.didww.com/v3/prices.csv.gz' }
  let(:last_modified) { 'Wed, 14 Oct 2026 06:00:00 GMT' }
  let(:not_modified_headers) do
    {
      'Content-Disposition' => 'attachment; filename="voice_in_prices.csv.gz"',
      'Last-Modified' => last_modified,
      'Cache-Control' => 'private',
      'Accept-Ranges' => 'none',
      'Vary' => 'Authorization'
    }
  end
  let(:file_headers) { not_modified_headers.merge('Content-Type' => 'application/gzip', 'Content-Length' => gzip_fixture.bytesize.to_s) }
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, 'voice_in_prices.csv.gz') }
  let(:io) { StringIO.new(String.new(encoding: Encoding::BINARY)) }

  before { stub_didww_token(aud: 'api-vin.didww.com') }

  after { FileUtils.remove_entry(dir) }

  describe 'price file endpoints' do
    {
      voice_in: ['https://api-vin-sandbox.didww.com/v3/prices.csv.gz', 'api-vin.didww.com'],
      voice_out: ['https://api-vout-sandbox.didww.com/v3/prices.csv.gz', 'api-vout.didww.com'],
      sms_out_a2p: ['https://api-sms-sandbox.didww.com/v3/sms_out/a2p/prices.csv.gz', 'api-sms.didww.com'],
      sms_out_p2p: ['https://api-sms-sandbox.didww.com/v3/sms_out/p2p/prices.csv.gz', 'api-sms.didww.com'],
      sms_out_otp: ['https://api-sms-sandbox.didww.com/v3/sms_out/otp/prices.csv.gz', 'api-sms.didww.com'],
      sms_in: ['https://api-sms-sandbox.didww.com/v3/sms_in/prices.csv.gz', 'api-sms.didww.com']
    }.each do |name, (uri, audience)|
      it "downloads the #{name} file from #{uri} with a token for #{audience}" do
        stub_didww_token(aud: audience)
        stub = stub_request(:get, uri).with(headers: prices_request_headers).to_return(status: 200, body: gzip_fixture, headers: file_headers)

        DIDWW::Prices.public_send(name).download(to: io)

        expect(stub).to have_been_requested.once
        expect(a_request(:post, token_uri).with(body: hash_including(aud: [audience]))).to have_been_made.once
      end
    end
  end

  describe '#download' do
    context 'when the file is served' do
      before { stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 200, body: gzip_fixture, headers: file_headers) }

      it 'writes the gzipped bytes unchanged to a path' do
        service.download(to: path)

        expect(File.binread(path)).to eq(gzip_fixture)
        expect(Dir.children(dir)).to eq(['voice_in_prices.csv.gz'])
      end

      it 'writes to a Pathname through the path branch' do
        service.download(to: Pathname.new(path))

        expect(File.binread(path)).to eq(gzip_fixture)
        expect(File.mtime(path)).to eq(Time.utc(2026, 10, 14, 6, 0, 0))
      end

      it 'sets the modification time of the file to Last-Modified' do
        service.download(to: path)

        expect(File.mtime(path)).to eq(Time.utc(2026, 10, 14, 6, 0, 0))
      end

      it 'leaves the temp file of a concurrent download to the same path alone' do
        File.binwrite("#{path}.tmp", 'concurrent download')

        service.download(to: path)

        expect(File.binread(path)).to eq(gzip_fixture)
        expect(File.binread("#{path}.tmp")).to eq('concurrent download')
        expect(Dir.children(dir)).to contain_exactly('voice_in_prices.csv.gz', 'voice_in_prices.csv.gz.tmp')
      end

      it 'writes each download through a temp file of its own' do
        tmp_paths = []
        allow(File).to receive(:open).and_wrap_original do |original, file_path, *args, **options, &block|
          tmp_paths << file_path if file_path.to_s.start_with?("#{path}.")
          original.call(file_path, *args, **options, &block)
        end

        2.times { service.download(to: path) }

        expect(tmp_paths.size).to eq(2)
        expect(tmp_paths.uniq.size).to eq(2)
        expect(tmp_paths).to all match(/\A#{Regexp.escape(path)}\.\h{16}\.tmp\z/)
      end

      it 'writes the gzipped bytes unchanged to an IO' do
        service.download(to: io)

        expect(io.string).to eq(gzip_fixture)
      end

      it 'returns the file headers' do
        expect(service.download(to: io)).to have_attributes(
          status: :ok,
          modified?: true,
          last_modified: Time.utc(2026, 10, 14, 6, 0, 0),
          content_length: gzip_fixture.bytesize,
          filename: 'voice_in_prices.csv.gz',
          bytes_written: gzip_fixture.bytesize
        )
      end

      it 'sends If-Modified-Since given as a Time' do
        service.download(to: io, if_modified_since: Time.utc(2026, 10, 14, 6, 0, 0))

        expect(a_request(:get, file_uri).with(headers: { 'If-Modified-Since' => last_modified })).to have_been_made.once
      end

      it 'sends no If-Modified-Since by default' do
        service.download(to: io)

        expect(a_request(:get, file_uri).with { |request| !request.headers.key?('If-Modified-Since') }).to have_been_made.once
      end
    end

    context 'when the file has not changed' do
      before do
        File.binwrite(path, 'previous copy')
        stub_request(:get, file_uri)
          .with(headers: prices_request_headers.merge('If-Modified-Since' => last_modified))
          .to_return(status: 304, body: '', headers: not_modified_headers)
      end

      it 'keeps the file at the path' do
        expect(service.download(to: path, if_modified_since: last_modified)).to have_attributes(status: :not_modified, not_modified?: true, bytes_written: 0, content_length: nil)
        expect(File.binread(path)).to eq('previous copy')
        expect(Dir.children(dir)).to eq(['voice_in_prices.csv.gz'])
      end

      it 'leaves the temp file of a concurrent download to the same path alone' do
        File.binwrite("#{path}.tmp", 'concurrent download')

        service.download(to: path, if_modified_since: last_modified)

        expect(File.binread("#{path}.tmp")).to eq('concurrent download')
      end
    end

    context 'when the token is refused once' do
      before do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz')
          .to_return(status: 401, body: '{"errors":[{"title":"Unauthorized","code":"401","status":"401"}]}', headers: json_api_headers)
          .then.to_return(status: 200, body: gzip_fixture, headers: file_headers)
      end

      it 'mints a new token and writes only the file bytes' do
        service.download(to: path)

        expect(File.binread(path)).to eq(gzip_fixture)
        expect(a_request(:get, file_uri)).to have_been_made.twice
        expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-vin.didww.com']))).to have_been_made.twice
      end
    end

    context 'when the token is refused twice' do
      before do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz')
          .to_return(status: 401, body: '{"errors":[{"title":"Unauthorized","detail":"Authorization failed","code":"401","status":"401"}]}', headers: json_api_headers)
      end

      it 'raises NotAuthorized and writes nothing' do
        expect { service.download(to: path) }.to raise_error(DIDWW::Prices::NotAuthorized, 'Authorization failed') { |error| expect(error).to have_attributes(status: 401, code: '401') }
        expect(Dir.children(dir)).to eq([])
      end
    end

    context 'when no price plan is assigned' do
      before do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz')
          .to_return(status: 404, body: api_fixture('prices/errors/price_plan_not_assigned'), headers: json_api_headers)
      end

      it 'raises PricePlanNotAssigned' do
        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::PricePlanNotAssigned, 'No price plan is assigned to this account.') { |error| expect(error).to have_attributes(status: 404, code: 'price_plan_not_assigned') }
        expect(io.string).to eq('')
      end
    end

    context 'when the token lacks the read scope' do
      before do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz')
          .to_return(status: 403, body: '{"errors":[{"title":"Insufficient scope","code":"403","status":"403"}]}', headers: json_api_headers)
      end

      it 'raises AccessDenied without minting again' do
        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::AccessDenied, 'Insufficient scope')
        expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-vin.didww.com']))).to have_been_made.once
      end
    end

    context 'when the request budget is spent' do
      before do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz')
          .to_return(status: 429, body: '', headers: { 'Retry-After' => '30' })
      end

      it 'raises TooManyRequests without retrying' do
        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::TooManyRequests) { |error| expect(error).to have_attributes(status: 429, retry_after: 30) }
        expect(a_request(:get, file_uri)).to have_been_made.once
        expect(sleeps).to eq([])
      end
    end

    context 'when the connection fails' do
      before do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_raise(Faraday::ConnectionFailed.new('connection refused'))
      end

      it 'raises ConnectionError and keeps the existing file' do
        File.binwrite(path, 'old copy')

        expect { service.download(to: path) }.to raise_error(DIDWW::Prices::ConnectionError, 'connection refused')
        expect(File.binread(path)).to eq('old copy')
      end
    end

    context 'when the IO cannot be written' do
      before { stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 200, body: gzip_fixture, headers: file_headers) }

      it 'raises the write error' do
        io.close_write

        expect { service.download(to: io) }.to raise_error(IOError, 'not opened for writing')
      end

      it 'raises a system write error' do
        allow(io).to receive(:write).and_raise(Errno::EPIPE)

        expect { service.download(to: io) }.to raise_error(Errno::EPIPE)
      end

      it 'raises a write error the adapter would wrap' do
        allow(io).to receive(:write).and_raise(OpenSSL::SSL::SSLError, 'SSL_write: bad write retry')

        expect { service.download(to: io) }.to raise_error(OpenSSL::SSL::SSLError, 'SSL_write: bad write retry')
      end
    end

    context 'when the file is not generated yet' do
      let(:unavailable) { { status: 503, body: api_fixture('prices/errors/serving_failure'), headers: json_api_headers.merge('Retry-After' => '1') } }

      it 'waits Retry-After and retries' do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz')
          .to_return(unavailable)
          .then.to_return(status: 200, body: gzip_fixture, headers: file_headers)

        service.download(to: io)

        expect(io.string).to eq(gzip_fixture)
        expect(sleeps).to eq([1])
      end

      it 'raises ServiceUnavailable after two retries' do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(unavailable)

        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::ServiceUnavailable, 'The price file is not available yet.') { |error| expect(error).to have_attributes(status: 503, code: 'serving_failure', retry_after: 1) }
        expect(a_request(:get, file_uri)).to have_been_made.times(3)
        expect(sleeps).to eq([1, 1])
      end

      it 'raises ServiceUnavailable at once when Retry-After is over a minute' do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(unavailable.merge(headers: json_api_headers.merge('Retry-After' => '120')))

        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::ServiceUnavailable) { |error| expect(error.retry_after).to eq(120) }
        expect(a_request(:get, file_uri)).to have_been_made.once
        expect(sleeps).to eq([])
      end

      it 'raises ServiceUnavailable at once without Retry-After' do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(unavailable.merge(headers: json_api_headers))

        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::ServiceUnavailable) { |error| expect(error.retry_after).to be_nil }
        expect(a_request(:get, file_uri)).to have_been_made.once
      end
    end

    context 'when the answer is not documented' do
      it 'raises UnexpectedStatus on 202' do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 202, body: '')

        expect { service.download(to: path) }.to raise_error(DIDWW::Prices::UnexpectedStatus, 'Prices service responded with status 202')
        expect(Dir.children(dir)).to eq([])
      end

      it 'raises UnexpectedStatus on a redirect without following it' do
        stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 302, body: '', headers: { 'Location' => 'https://example.com/prices.csv.gz' })

        expect { service.download(to: io) }.to raise_error(DIDWW::Prices::UnexpectedStatus) { |error| expect(error.status).to eq(302) }
        expect(a_request(:get, 'https://example.com/prices.csv.gz')).not_to have_been_made
      end
    end
  end

  describe '#head' do
    it 'returns the file headers' do
      stub_prices_request(:voice_in, :head, '/prices.csv.gz').to_return(status: 200, body: '', headers: file_headers)

      expect(service.head).to have_attributes(
        status: :ok,
        last_modified: Time.utc(2026, 10, 14, 6, 0, 0),
        content_length: gzip_fixture.bytesize,
        filename: 'voice_in_prices.csv.gz',
        bytes_written: nil
      )
    end

    it 'returns not modified for the Last-Modified held' do
      stub_request(:head, file_uri)
        .with(headers: prices_request_headers.merge('If-Modified-Since' => last_modified))
        .to_return(status: 304, body: '', headers: not_modified_headers)

      expect(service.head(if_modified_since: last_modified)).to have_attributes(status: :not_modified, last_modified: Time.utc(2026, 10, 14, 6, 0, 0))
    end

    it 'raises PricePlanNotAssigned on 404 without a body' do
      stub_prices_request(:voice_in, :head, '/prices.csv.gz').to_return(status: 404, body: '')

      expect { service.head }.to raise_error(DIDWW::Prices::PricePlanNotAssigned) { |error| expect(error).to have_attributes(status: 404, code: 'price_plan_not_assigned', errors: []) }
    end

    it 'waits Retry-After and retries on 503' do
      stub_prices_request(:voice_in, :head, '/prices.csv.gz')
        .to_return(status: 503, body: '', headers: { 'Retry-After' => '2' })
        .then.to_return(status: 200, body: '', headers: file_headers)

      expect(service.head.status).to eq(:ok)
      expect(sleeps).to eq([2])
    end
  end

  describe '#fetch' do
    let(:other_last_modified) { 'Thu, 15 Oct 2026 06:00:00 GMT' }

    it 'downloads the file without If-Modified-Since when there is no copy' do
      stub = stub_prices_request(:voice_in, :get, '/prices.csv.gz')
        .with { |request| !request.headers.key?('If-Modified-Since') }
        .to_return(status: 200, body: gzip_fixture, headers: file_headers)

      expect(service.fetch(path).status).to eq(:ok)
      expect(File.binread(path)).to eq(gzip_fixture)
      expect(stub).to have_been_requested.once
    end

    it 'sends the modification time of the copy on disk as If-Modified-Since' do
      File.binwrite(path, 'previous copy')
      File.utime(Time.utc(2026, 10, 14, 6, 0, 0), Time.utc(2026, 10, 14, 6, 0, 0), path)
      stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 304, body: '', headers: not_modified_headers)

      expect(service.fetch(path).status).to eq(:not_modified)
      expect(File.binread(path)).to eq('previous copy')
      expect(a_request(:get, file_uri).with(headers: { 'If-Modified-Since' => last_modified })).to have_been_made.once
    end

    it 'sends the date of an older copy that replaced the downloaded one' do
      stub_prices_request(:voice_in, :get, '/prices.csv.gz')
        .to_return(status: 200, body: gzip_fixture, headers: file_headers.merge('Last-Modified' => other_last_modified))
        .then.to_return(status: 200, body: gzip_fixture, headers: file_headers.merge('Last-Modified' => other_last_modified))

      service.fetch(path)
      File.binwrite(path, 'older copy')
      File.utime(Time.utc(2026, 10, 14, 6, 0, 0), Time.utc(2026, 10, 14, 6, 0, 0), path)

      expect(service.fetch(path).status).to eq(:ok)
      expect(File.binread(path)).to eq(gzip_fixture)
      expect(a_request(:get, file_uri).with(headers: { 'If-Modified-Since' => last_modified })).to have_been_made.once
    end

    it 'sends the Last-Modified of the previous download and keeps the copy on 304' do
      stub_prices_request(:voice_in, :get, '/prices.csv.gz')
        .to_return(status: 200, body: gzip_fixture, headers: file_headers)
        .then.to_return(status: 304, body: '', headers: not_modified_headers)

      service.fetch(path)

      expect(service.fetch(path).status).to eq(:not_modified)
      expect(File.binread(path)).to eq(gzip_fixture)
      expect(Dir.children(dir)).to eq(['voice_in_prices.csv.gz'])
      expect(a_request(:get, file_uri).with(headers: { 'If-Modified-Since' => last_modified })).to have_been_made.once
    end

    it 'replaces the copy and dates it with the new Last-Modified when the file changed' do
      stub_prices_request(:voice_in, :get, '/prices.csv.gz')
        .to_return(status: 200, body: 'previous copy', headers: file_headers.merge('Content-Length' => '13'))
        .then.to_return(status: 200, body: gzip_fixture, headers: file_headers.merge('Last-Modified' => other_last_modified))
        .then.to_return(status: 304, body: '', headers: not_modified_headers)

      service.fetch(path)
      service.fetch(path)
      service.fetch(path)

      expect(File.binread(path)).to eq(gzip_fixture)
      expect(File.mtime(path)).to eq(Time.utc(2026, 10, 15, 6, 0, 0))
      expect(a_request(:get, file_uri).with(headers: { 'If-Modified-Since' => last_modified })).to have_been_made.once
      expect(a_request(:get, file_uri).with(headers: { 'If-Modified-Since' => other_last_modified })).to have_been_made.once
    end

    it 'sends no If-Modified-Since when the copy was removed' do
      stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 200, body: gzip_fixture, headers: file_headers)

      service.fetch(path)
      File.delete(path)
      service.fetch(path)

      expect(a_request(:get, file_uri).with { |request| !request.headers.key?('If-Modified-Since') }).to have_been_made.twice
    end

    it 'never sends If-None-Match' do
      stub_prices_request(:voice_in, :get, '/prices.csv.gz').to_return(status: 200, body: gzip_fixture, headers: file_headers)

      service.fetch(path)
      service.fetch(path)

      expect(a_request(:get, file_uri).with { |request| !request.headers.key?('If-None-Match') }).to have_been_made.twice
    end
  end

  describe '.each_row' do
    it 'reads the rows of a gzipped price file' do
      rows = DIDWW::Prices.each_row(fixture_path).map(&:to_h)

      expect(rows.size).to eq(4)
      expect(rows.first).to eq(
        'Country' => 'United Kingdom',
        'Src country name' => nil,
        'Source type' => 'cellular',
        'Destination' => '44800',
        'Rate (USD, excl. VAT)' => nil,
        'Connection fee (USD, excl. VAT)' => nil,
        'Initial interval' => '60',
        'Next interval' => '60',
        'Reject calls' => 'true'
      )
    end

    it 'yields each row to a block' do
      destinations = []

      DIDWW::Prices.each_row(fixture_path) { |row| destinations << row['Destination'] }

      expect(destinations).to eq(%w[44800 4480012 1800 1800])
    end
  end
end
