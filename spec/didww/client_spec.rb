# frozen_string_literal: true
RSpec.describe DIDWW::Client do
  let(:api_key) { 'f02c46006f6fa4746cd019abffb0a949' }
  let(:sandbox_uri) { 'https://sandbox-api.didww.com/v3/' }
  let(:prod_uri) { 'https://api.didww.com/v3/' }

  before(:each) do
    DIDWW.send(:remove_const, :Client)
    load 'didww/client.rb'
  end

  it 'configures' do
    DIDWW::Client.configure do |client|
      client.api_key  = api_key
      client.api_mode = :production
    end

    expect(DIDWW::Client.api_key).to eq(api_key)
    expect(DIDWW::Client.api_mode).to eq(:production)
    expect(DIDWW::Client.api_base_url).to eq(prod_uri)
  end

  it 'defaults to sandbox mode' do
    DIDWW::Client.configure do |client|
      client.api_key = api_key
    end
    expect(DIDWW::Client.api_mode).to eq(:sandbox)
    expect(DIDWW::Client.api_base_url).to eq(sandbox_uri)
  end

  it 'mode can only be :sandbox or :production' do
    DIDWW::Client.configure do |client|
      client.api_key = api_key
      DIDWW::Client.api_mode = :sandbox
      DIDWW::Client.api_mode = :production
      expect { DIDWW::Client.api_mode = :other }.to raise_error(ArgumentError)
    end
  end
end
