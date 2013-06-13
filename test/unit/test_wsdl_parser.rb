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
              'accountId' => {
                :name     => 'accountId',
                :prefix   => 'xsd1',
                :type     => 'xs:string',
                :singular => true
              },
              'tickerSymbol' => {
                :name     => 'tickerSymbol',
                :prefix   => 'xsd1',
                :type     => 'xs:string',
                :singular => false
              },
              'specialTickerSymbol' => {
                :name     => 'specialTickerSymbol',
                :prefix   => 'xsd1',
                :type     => 'xsd2:TickerSymbol',
                :singular => false
              }
            },
            :attributes => ['signature', 'id']
          },
          'xsd1:HistoricalPriceRequest' => {
            :prefix   => 'xsd1',
            :name     => 'HistoricalPriceRequest',
            :elements => {
              'accountId' => {
                :name     => 'accountId',
                :prefix   => 'xsd1',
                :type     => 'xs:string',
                :singular => true
              },
              'dateRange' => {
                :name     => 'dateRange',
                :prefix   => 'xsd1',
                :type     => {
                  :elements => {
                    'startDate' => {
                      :name     => 'startDate',
                      :prefix   => 'xsd1',
                      :type     => 'xs:string',
                      :singular => true
                    },
                    'endDate' => {
                      :name     => 'endDate',
                      :prefix   => 'xsd1',
                      :type     => 'xs:string',
                      :singular => true
                    }
                  },
                  :attributes => []
                },
                :singular => true
              }
            },
            :attributes => ['signature']
          },
          'xsd2:TickerSymbol' => {
            :prefix   => 'xsd2',
            :name     => 'TickerSymbol',
            :elements => {
              'name' => {
                :name     => 'name',
                :prefix   => 'xsd2',
                :type     => 'xs:string',
                :singular => true
              }
            },
            :attributes => []
          }
        })
      end
    end

    describe '#elements' do
      it 'returns the elements with inline types' do
        subject.elements.must_equal({
          "xsd1:TradePrice" => {
            :name   => "TradePrice",
            :prefix => "xsd1",
            :type   => {
              :elements => {
                'price' => {
                  :name     => 'price',
                  :prefix   => 'xsd1',
                  :type     => 'xs:float',
                  :singular => true
                }
              },
              :attributes => []
            }
          },
          "xsd1:HistoricalPrice" => {
            :name   => "HistoricalPrice",
            :prefix => "xsd1",
            :type   => {
              :elements => {
                'date' => {
                  :name     => 'date',
                  :prefix   => 'xsd1',
                  :type     => 'xs:date',
                  :singular => true
                },
                'price' => {
                  :name     => 'price',
                  :prefix   => 'xsd1',
                  :type     => 'xs:float',
                  :singular => true
                }
              },
              :attributes => []
            }
          }
        })
      end
    end

    describe '#messages' do
      it 'maps message names to types' do
        subject.messages.must_equal({
          'GetLastTradePriceInput'   => 'xsd1:TradePriceRequest',
          'GetLastTradePriceOutput'  => 'xsd1:TradePrice',
          'GetHistoricalPriceInput'  => 'xsd1:HistoricalPriceRequest',
          'GetHistoricalPriceOutput' => 'xsd1:HistoricalPrice'
        })
      end
    end

    describe '#port_type_operations' do
      it 'is a hash containing input and output types' do
        subject.port_type_operations.must_equal({
          'GetLastTradePrice' => {
            :input  => 'xsd1:TradePriceRequest',
            :output => 'xsd1:TradePrice'
          },
          'GetHistoricalPrice' => {
            :input  => 'xsd1:HistoricalPriceRequest',
            :output => 'xsd1:HistoricalPrice'
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
          },
          'GetHistoricalPrice' => {
            :action => 'http://example.com/GetHistoricalPrice',
            :input  => 'xsd1:HistoricalPriceRequest',
            :output => 'xsd1:HistoricalPrice'
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
