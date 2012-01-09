require 'helper'
require 'lolsoap/wsdl_parser'

module LolSoap
  describe WSDLParser do
    subject { WSDLParser.new(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }

    describe '#namespaces' do
      it 'returns the namespaces used' do
        subject.namespaces.must_equal({
          'tns'  => 'http://example.com/stockquote.wsdl',
          'xsd1' => 'http://example.com/stockquote.xsd',
          'soap' => 'http://schemas.xmlsoap.org/wsdl/soap12/'
        })
      end
    end

    describe '#endpoint' do
      it 'returns the SOAP 1.2 service endpoint' do
        subject.endpoint.must_equal 'http://example.com/stockquote'
      end
    end

    describe '#types' do
      it 'returns the types, with attributes and namespace' do
        subject.types.must_equal({
          'TradePriceRequest' => {
            :name      => 'TradePriceRequest',
            :namespace => 'http://example.com/stockquote.xsd',
            :elements  => { 'tickerSymbol' => 'string' }
          },
          'TradePrice' => {
            :name      => 'TradePrice',
            :namespace => 'http://example.com/stockquote.xsd',
            :elements  => { 'price' => 'float' }
          }
        })
      end
    end

    describe '#messages' do
      it 'maps message names to types' do
        subject.messages.must_equal({
          'GetLastTradePriceInput'  => subject.types['TradePriceRequest'],
          'GetLastTradePriceOutput' => subject.types['TradePrice']
        })
      end
    end

    describe '#port_type_operations' do
      it 'is a hash containing input and output types' do
        subject.port_type_operations.must_equal({
          'GetLastTradePrice' => {
            :name   => 'GetLastTradePrice',
            :input  => subject.types['TradePriceRequest'],
            :output => subject.types['TradePrice']
          }
        })
      end
    end

    describe '#operations' do
      it 'is a hash of operations with their action and input type' do
        subject.operations.must_equal({
          'GetLastTradePrice' => {
            :name => 'GetLastTradePrice',
            :action => 'http://example.com/GetLastTradePrice',
            :input => subject.types['TradePriceRequest']
          }
        })
      end
    end
  end
end
