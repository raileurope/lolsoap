require 'helper'
require 'lolsoap/client'

module LolSoap
  describe Client do
    subject { Client.new(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }

    it 'builds a request' do
      request = subject.request('GetLastTradePrice')
      request.body { |foo| foo.bar }
      request.content.empty?.must_equal false
    end

    it 'builds a response' do
      request = subject.request('GetLastTradePrice')
      response = subject.response(request, File.read(TEST_ROOT + '/fixtures/stock_quote_response.xml'))
      response.body.wont_equal nil
    end
  end
end
