require 'helper'
require 'lolsoap/wsdl_parser'

module LolSoap
  describe WSDLParser do
    def raw_doc
      File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')
    end

    let(:doc) { Nokogiri::XML(raw_doc) }

    subject { WSDLParser.new(doc) }

    describe '#namespaces' do
      it 'returns the namespaces used' do
        subject.namespaces.must_equal({
          'tns'  => 'http://example.com/stockquote.wsdl',
          'xsd1' => 'http://example.com/stockquote.xsd',
          'xsd2' => 'http://example.com/stockquote2.xsd',
          'xsd3' => 'http://example.com/stockquote.xsd',
          'soap' => 'http://schemas.xmlsoap.org/wsdl/soap12/',
          'xs'   => 'http://www.w3.org/2001/XMLSchema'
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
          'xsd1:TradePriceRequest' => {
            :prefix   => 'xsd1',
            :name     => 'TradePriceRequest',
            :elements => {
              'tickerSymbol' => {
                :type     => 'xs:string',
                :singular => false
              },
              'specialTickerSymbol' => {
                :type     => 'xsd2:TickerSymbol',
                :singular => false
              }
            },
            :attributes => ['id']
          },
          'xsd1:TradePrice' => {
            :prefix   => 'xsd1',
            :name     => 'TradePrice',
            :elements => {
              'price' => {
                :type     => 'xs:float',
                :singular => true
              }
            },
            :attributes => []
          },
          'xsd2:TickerSymbol' => {
            :prefix   => 'xsd2',
            :name     => 'TickerSymbol',
            :elements => {
              'name' => {
                :type     => 'xs:string',
                :singular => true
              }
            },
            :attributes => []
          }
        })
      end
    end

    describe '#messages' do
      it 'maps message names to types' do
        subject.messages.must_equal({
          'GetLastTradePriceInput'  => 'xsd1:TradePriceRequest',
          'GetLastTradePriceOutput' => 'xsd1:TradePrice'
        })
      end
    end

    describe '#port_type_operations' do
      it 'is a hash containing input and output types' do
        subject.port_type_operations.must_equal({
          'GetLastTradePrice' => {
            :input  => 'xsd1:TradePriceRequest',
            :output => 'xsd1:TradePrice'
          }
        })
      end
    end

    describe '#operations' do
      it 'is a hash of operations with their action and input type' do
        subject.operations.must_equal({
          'GetLastTradePrice' => {
            :action => 'http://example.com/GetLastTradePrice',
            :input  => 'xsd1:TradePriceRequest',
            :output => 'xsd1:TradePrice'
          }
        })
      end
    end

    describe 'soap 1.1' do
      def raw_doc
        super.sub("http://schemas.xmlsoap.org/wsdl/soap12/", "http://schemas.xmlsoap.org/wsdl/soap/")
      end

      it 'is supported' do
        subject.operations.empty?.must_equal false
      end
    end
  end
end
