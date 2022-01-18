require 'helper'
require 'lolsoap/client'

module LolSoap
  describe Response do
    let(:client) { LolSoap::Client.new File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl') }
    let(:request) { client.request('GetLastTradePrice') }

    subject { Response.parse(request, File.read(TEST_ROOT + '/fixtures/stock_quote_response.xml')) }
    let(:ox_subject) { Response.parse(request, File.read(TEST_ROOT + '/fixtures/stock_quote_response.xml'), use_ox: true) }

    it 'should build a hash from the body' do
      subject.body_hash.must_equal({ 'Price' => '34.5' })
    end

    it 'should build a hash from the body when using Ox' do
      ox_subject.body_hash.must_equal({ 'Price' => '34.5' })
    end
  end
end
