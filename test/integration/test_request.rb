require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/request'

module LolSoap
  describe Request do
    let(:wsdl) { WSDL.parse(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }
    let(:operation) { wsdl.operation('GetLastTradePrice') }
    let(:envelope) { Envelope.new(wsdl, operation) }

    subject { Request.new(envelope) }

    it 'should put together a HTTP request' do
      subject.url.must_equal "http://example.com/stockquote"
      subject.headers['SOAPAction'].must_equal "http://example.com/GetLastTradePrice"
      subject.content.empty?.must_equal false
    end
  end
end
