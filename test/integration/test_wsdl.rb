require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    subject { WSDL.parse(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }

    it 'should successfully parse a WSDL document' do
      subject.operations.length.must_equal 2
      subject.operations.fetch('GetLastTradePrice').tap do |o|
        o.input.header.tap do |header|
          header.name.must_equal 'Header'
          header.content.must_equal nil
          header.content_type.elements.keys.size.must_equal 2
          header.content_type.elements.keys.first.must_equal 'tradePriceRequestHeader'
          header.content_type.elements.keys.last.must_equal 'authentication'
        end
        o.input.body.name.must_equal 'Body'
        o.input.body.content.name.must_equal 'tradePriceRequest'
        o.action.must_equal 'http://example.com/GetLastTradePrice'
      end

      subject.operations.fetch('GetHistoricalPrice').tap do |o|
        o.input.header.name.must_equal 'Header'
        o.input.header.content.must_equal nil
        o.input.header.content_type.class.must_equal WSDL::NullType
        o.input.body.name.must_equal 'Body'
        o.input.body.content.name.must_equal 'historicalPriceRequest'
      end

      subject.abstract_types.length.must_equal 1
      subject.abstract_types.fetch('BaseRequest').tap do |t|
        t.prefix.must_equal 'ns0'
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
