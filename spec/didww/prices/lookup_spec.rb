# frozen_string_literal: true
RSpec.describe DIDWW::Prices::Service do
  let(:lookup_headers) { prices_request_headers.merge('Accept' => 'application/vnd.api+json') }

  describe '#lookup' do
    context 'with Voice IN prices' do
      subject(:service) { DIDWW::Prices.voice_in }

      let(:lookup_uri) { 'https://api-vin-sandbox.didww.com/v3/lookup/prices' }

      before { stub_didww_token(aud: 'api-vin.didww.com') }

      it 'requests the Voice IN host with filter[number] and a token for its audience' do
        stub = stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '18005550123' } }, headers: lookup_headers)
          .to_return(status: 200, body: api_fixture('prices/voice_in/lookup/200'), headers: json_api_headers)

        service.lookup(number: '18005550123')

        expect(stub).to have_been_requested.once
        expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-vin.didww.com']))).to have_been_made.once
      end

      it 'sends filter[src_country_iso]' do
        stub = stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '448001234567', src_country_iso: 'GB' } }, headers: lookup_headers)
          .to_return(status: 200, body: api_fixture('prices/voice_in/lookup/200'), headers: json_api_headers)

        service.lookup(number: 448_001_234_567, src_country_iso: 'GB')

        expect(stub).to have_been_requested.once
      end

      it 'returns Voice IN prices with decimal values' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '18005550123' } })
          .to_return(status: 200, body: api_fixture('prices/voice_in/lookup/200'), headers: json_api_headers)

        result = service.lookup(number: '18005550123')

        expect(result).to be_an_instance_of(DIDWW::Prices::LookupResult)
        expect(result.total_records).to eq(2)
        expect(result.map(&:to_h)).to eq(
          [
            {
              id: 'df73d9e4-46ce-4af0-817e-f090dc8144f1',
              destination: '1800',
              country: 'United States',
              src_country_name: nil,
              source_type: 'cellular',
              rate: BigDecimal('0.025'),
              connection_fee: BigDecimal('0.0'),
              initial_interval: 60,
              next_interval: 60,
              reject_calls: false
            },
            {
              id: 'cb1335e1-6cfd-4921-8724-153d9ed67ac3',
              destination: '44800',
              country: 'United Kingdom',
              src_country_name: 'United Kingdom',
              source_type: 'fixed',
              rate: nil,
              connection_fee: nil,
              initial_interval: 60,
              next_interval: 60,
              reject_calls: true
            }
          ]
        )
        expect(result.first).to be_an_instance_of(DIDWW::Prices::VoiceInPrice)
        expect(result.first.rate).to be_an_instance_of(BigDecimal)
      end

      it 'raises ArgumentError without filter[number]' do
        expect { service.lookup(src_country_iso: 'GB') }.to raise_error(ArgumentError, 'Filter number is required on lookup/prices.')
        expect(a_request(:get, /lookup/)).not_to have_been_made
      end

      it 'raises ArgumentError for a blank filter[number]' do
        expect { service.lookup(number: '') }.to raise_error(ArgumentError, 'Filter number is required on lookup/prices.')
      end

      it 'raises ArgumentError for a filter it does not declare' do
        expect { service.lookup(number: '18005550123', dst_country_iso: 'US') }.to raise_error(ArgumentError, 'Filter dst_country_iso is not allowed on lookup/prices (allowed: number, src_country_iso).')
        expect(a_request(:get, /lookup/)).not_to have_been_made
      end

      it 'raises PriceNotFound when no prefix covers the number' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '99912345678' } })
          .to_return(status: 404, body: api_fixture('prices/errors/price_not_found'), headers: json_api_headers)

        expect { service.lookup(number: '99912345678') }.to raise_error(DIDWW::Prices::PriceNotFound, 'No effective price covers this number in the assigned plan.') { |error| expect(error).to have_attributes(status: 404, code: 'price_not_found') }
      end

      it 'raises PricePlanNotAssigned when the account has no plan' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '18005550123' } })
          .to_return(status: 404, body: api_fixture('prices/errors/price_plan_not_assigned'), headers: json_api_headers)

        expect { service.lookup(number: '18005550123') }.to raise_error(DIDWW::Prices::PricePlanNotAssigned) { |error| expect(error.code).to eq('price_plan_not_assigned') }
      end

      it 'mints a new token and retries once when the token is refused' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '18005550123' } })
          .to_return(status: 401, body: '{"errors":[{"title":"Unauthorized","code":"401","status":"401"}]}', headers: json_api_headers)
          .then.to_return(status: 200, body: api_fixture('prices/voice_in/lookup/200'), headers: json_api_headers)

        expect(service.lookup(number: '18005550123').total_records).to eq(2)
        expect(a_request(:get, lookup_uri).with(query: { filter: { number: '18005550123' } })).to have_been_made.twice
        expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-vin.didww.com']))).to have_been_made.twice
      end

      {
        401 => [DIDWW::Prices::NotAuthorized, '{"errors":[{"title":"Unauthorized","code":"401","status":"401"}]}'],
        403 => [DIDWW::Prices::AccessDenied, '{"errors":[{"title":"Insufficient scope","code":"403","status":"403"}]}'],
        406 => [DIDWW::Prices::NotAcceptable, '{"errors":[{"title":"Not acceptable","code":"406","status":"406"}]}'],
        500 => [DIDWW::Prices::UnexpectedStatus, '']
      }.each do |status, (error_class, body)|
        it "raises #{error_class} on #{status}" do
          stub_request(:get, lookup_uri)
            .with(query: { filter: { number: '18005550123' } })
            .to_return(status: status, body: body, headers: json_api_headers)

          expect { service.lookup(number: '18005550123') }.to raise_error(error_class) { |error| expect(error.status).to eq(status) }
        end
      end

      it 'raises TooManyRequests with Retry-After' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '18005550123' } })
          .to_return(status: 429, body: '{"errors":[{"title":"Too many requests","code":"too_many_requests","status":"429"}]}', headers: json_api_headers.merge('Retry-After' => '7'))

        expect { service.lookup(number: '18005550123') }.to raise_error(DIDWW::Prices::TooManyRequests) { |error| expect(error).to have_attributes(code: 'too_many_requests', retry_after: 7) }
        expect(a_request(:get, lookup_uri).with(query: { filter: { number: '18005550123' } })).to have_been_made.once
      end

      it 'raises ConnectionError on a timeout' do
        stub_request(:get, lookup_uri).with(query: { filter: { number: '18005550123' } }).to_timeout

        expect { service.lookup(number: '18005550123') }.to raise_error(DIDWW::Prices::ConnectionError)
      end

      it 'raises ConnectionError when the TLS handshake fails' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '18005550123' } })
          .to_raise(Faraday::SSLError.new('certificate verify failed'))

        expect { service.lookup(number: '18005550123') }.to raise_error(DIDWW::Prices::ConnectionError, 'certificate verify failed')
      end
    end

    context 'with Voice OUT prices' do
      subject(:service) { DIDWW::Prices.voice_out }

      let(:lookup_uri) { 'https://api-vout-sandbox.didww.com/v3/lookup/prices' }

      before { stub_didww_token(aud: 'api-vout.didww.com') }

      it 'returns Voice OUT prices with decimal and time values' do
        stub = stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '493012345678' } }, headers: lookup_headers)
          .to_return(status: 200, body: api_fixture('prices/voice_out/lookup/200'), headers: json_api_headers)

        result = service.lookup(number: '493012345678')

        expect(stub).to have_been_requested.once
        expect(result.total_records).to eq(2)
        expect(result.map(&:to_h)).to eq(
          [
            {
              id: '7b82cac2-c42a-4fa9-8da4-ccba2843068f',
              prefix: '4930',
              country: 'Germany',
              network: 'Fixed',
              rate: BigDecimal('0.0045'),
              connection_fee: BigDecimal('0.0'),
              initial_increment: 1,
              recurring_increment: 1,
              next_rate: BigDecimal('0.005'),
              next_connection_fee: BigDecimal('0.0'),
              next_initial_increment: 30,
              next_recurring_increment: 6,
              effective_at: Time.utc(2026, 11, 1, 0, 0, 0),
              comment: 'Increase and Billing increment change',
              reject_calls: false,
              category: DIDWW::Prices::VoiceOutPrice::CATEGORY_INTERNATIONAL
            },
            {
              id: '9159cccf-ec23-459a-b63b-94a0ade0fa51',
              prefix: '493',
              country: 'Germany',
              network: 'Fixed',
              rate: BigDecimal('0.0012'),
              connection_fee: BigDecimal('0.0'),
              initial_increment: 1,
              recurring_increment: 1,
              next_rate: nil,
              next_connection_fee: nil,
              next_initial_increment: nil,
              next_recurring_increment: nil,
              effective_at: nil,
              comment: nil,
              reject_calls: false,
              category: DIDWW::Prices::VoiceOutPrice::CATEGORY_ORIGIN_BASED
            }
          ]
        )
        expect(result.first).to be_an_instance_of(DIDWW::Prices::VoiceOutPrice)
      end

      it 'exposes the categories' do
        expect(DIDWW::Prices::VoiceOutPrice::CATEGORIES).to eq(['International', 'Origin based', 'Local'])
      end

      it 'raises ArgumentError for filter[src_country_iso] without a request' do
        expect { service.lookup(number: '493012345678', src_country_iso: 'DE') }.to raise_error(ArgumentError, 'Filter src_country_iso is not allowed on lookup/prices (allowed: number).')
        expect(a_request(:get, /lookup/)).not_to have_been_made
      end

      it 'raises BadRequest when the server refuses a filter' do
        stub_request(:get, lookup_uri)
          .with(query: { filter: { number: '1' } })
          .to_return(status: 400, body: api_fixture('prices/errors/filter_not_allowed'), headers: json_api_headers)

        expect { service.lookup(number: '1') }.to raise_error(DIDWW::Prices::BadRequest, 'src_country_iso is not allowed.') { |error| expect(error).to have_attributes(status: 400, code: '102') }
      end
    end

    {
      sms_out_a2p: 'sms_out/a2p/lookup/prices',
      sms_out_p2p: 'sms_out/p2p/lookup/prices',
      sms_out_otp: 'sms_out/otp/lookup/prices'
    }.each do |name, lookup_path|
      context "with #{name} prices" do
        subject(:service) { DIDWW::Prices.public_send(name) }

        let(:lookup_uri) { "https://api-sms-sandbox.didww.com/v3/#{lookup_path}" }

        before { stub_didww_token(aud: 'api-sms.didww.com') }

        it "requests #{lookup_path} on the SMS host with filter[dst_number]" do
          stub = stub_request(:get, lookup_uri)
            .with(query: { filter: { dst_number: '4915123456789' } }, headers: lookup_headers)
            .to_return(status: 200, body: api_fixture('prices/sms_out/lookup/200'), headers: json_api_headers)

          service.lookup(dst_number: '4915123456789')

          expect(stub).to have_been_requested.once
          expect(a_request(:post, token_uri).with(body: hash_including(aud: ['api-sms.didww.com']))).to have_been_made.once
        end

        it 'requests filter[dst_country_iso] alone' do
          stub = stub_request(:get, lookup_uri)
            .with(query: { filter: { dst_country_iso: 'FR' } }, headers: lookup_headers)
            .to_return(status: 200, body: api_fixture('prices/sms_out/lookup/200'), headers: json_api_headers)

          service.lookup(dst_country_iso: 'FR')

          expect(stub).to have_been_requested.once
        end

        it 'requests both filters' do
          stub = stub_request(:get, lookup_uri)
            .with(query: { filter: { dst_number: '4915123456789', dst_country_iso: 'DE' } }, headers: lookup_headers)
            .to_return(status: 200, body: api_fixture('prices/sms_out/lookup/200'), headers: json_api_headers)

          service.lookup(dst_number: '4915123456789', dst_country_iso: 'DE')

          expect(stub).to have_been_requested.once
        end

        it 'raises ArgumentError without filter[dst_number] and filter[dst_country_iso]' do
          expect { service.lookup }.to raise_error(ArgumentError, "One of filters dst_number, dst_country_iso is required on #{lookup_path}.")
          expect(a_request(:get, /lookup/)).not_to have_been_made
        end
      end
    end

    context 'with SMS OUT prices' do
      subject(:service) { DIDWW::Prices.sms_out_a2p }

      before { stub_didww_token(aud: 'api-sms.didww.com') }

      it 'returns SMS OUT prices with decimal values' do
        stub_request(:get, 'https://api-sms-sandbox.didww.com/v3/sms_out/a2p/lookup/prices')
          .with(query: { filter: { dst_number: '4915123456789' } })
          .to_return(status: 200, body: api_fixture('prices/sms_out/lookup/200'), headers: json_api_headers)

        result = service.lookup(dst_number: '4915123456789')

        expect(result.total_records).to eq(2)
        expect(result.map(&:to_h)).to eq(
          [
            {
              id: 'd8e4d372-42a6-4bb6-80ec-6c29c49aa9fd',
              source_prefix: nil,
              destination_prefix: '49151',
              country: 'Germany',
              mcc: 262,
              mcc_name: 'Germany',
              mnc: 1,
              mnc_name: 'Telekom Deutschland',
              reject_sms: false,
              price: BigDecimal('0.075')
            },
            {
              id: 'e554d414-527f-411f-b021-e63c554606c4',
              source_prefix: nil,
              destination_prefix: '49151',
              country: 'Germany',
              mcc: 262,
              mcc_name: 'Germany',
              mnc: 2,
              mnc_name: 'Vodafone',
              reject_sms: true,
              price: nil
            }
          ]
        )
        expect(result.first).to be_an_instance_of(DIDWW::Prices::SmsOutPrice)
      end
    end

    context 'with SMS IN prices' do
      subject(:service) { DIDWW::Prices.sms_in }

      let(:lookup_uri) { 'https://api-sms-sandbox.didww.com/v3/sms_in/lookup/prices' }

      before { stub_didww_token(aud: 'api-sms.didww.com') }

      it 'returns SMS IN prices with decimal values' do
        stub = stub_request(:get, lookup_uri)
          .with(query: { filter: { dst_number: '12025550123' } }, headers: lookup_headers)
          .to_return(status: 200, body: api_fixture('prices/sms_in/lookup/200'), headers: json_api_headers)

        result = service.lookup(dst_number: '12025550123')

        expect(stub).to have_been_requested.once
        expect(result.total_records).to eq(1)
        expect(result.map(&:to_h)).to eq(
          [
            {
              id: 'e93f925e-25ee-4060-bd50-a790b4945d3f',
              source_prefix: nil,
              source_number_length_min: 1,
              source_number_length_max: 15,
              destination_prefix: '1',
              destination_number_length_min: 11,
              destination_number_length_max: 11,
              country: 'United States',
              price: BigDecimal('0.005')
            }
          ]
        )
        expect(result.first).to be_an_instance_of(DIDWW::Prices::SmsInPrice)
      end

      it 'raises ArgumentError for filter[number]' do
        expect { service.lookup(number: '12025550123') }.to raise_error(ArgumentError, 'Filter number is not allowed on sms_in/lookup/prices (allowed: dst_number, dst_country_iso).')
      end
    end
  end
end
