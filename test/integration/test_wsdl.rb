require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    subject { WSDL.parse(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }

    it 'should successfully parse a WSDL document' do
      subject.operations.length.must_equal 2
      subject.operations.fetch('GetLastTradePrice').tap do |o|
        o.input.name.must_equal 'tradePriceRequest'
        o.action.must_equal     'http://example.com/GetLastTradePrice'
      end

      subject.types.length.must_equal 4
      subject.types.fetch('TradePriceRequest').tap do |t|
        t.prefix.must_equal 'ns0'
      end
    end

    describe '#inspect' do
      it 'works' do
        subject.inspect
      end
    end
  end
end
