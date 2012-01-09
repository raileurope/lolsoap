require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/wsdl'

module LolSoap
  describe Envelope do
    let(:wsdl) { WSDL.new(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }
    subject { Envelope.new(wsdl, wsdl.operations['GetLastTradePrice']) }

    it 'creates an empty envelope successfully' do
      doc  = subject.doc
      body = doc.at_xpath('/soap:Envelope/soap:Body/xsd1:TradePrice', doc.namespaces)
      body.wont_equal nil
    end
  end
end
