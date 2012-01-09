require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    subject { WSDL.new(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }

    it 'should successfully parse a WSDL document' do
      subject.operations.length.must_equal 1
      subject.operations['GetLastTradePrice'].tap do |o|
        o.input.must_equal  'TradePrice'
        o.action.must_equal 'http://example.com/GetLastTradePrice'
      end

      subject.types.length.must_equal 2
      subject.types['TradePrice'].tap do |t|
        t.name.must_equal 'TradePrice'
        t.namespace.must_equal 'http://example.com/stockquote.xsd'
      end
    end
  end
end
