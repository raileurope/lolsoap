require 'helper'
require 'lolsoap/wsdl_parser'

module LolSoap
  describe WSDLParser do
    def raw_doc
      File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')
    end

    let(:doc)        { Nokogiri::XML(raw_doc) }
    let(:namespace)  { "http://example.com/stockquote.xsd" }
    let(:namespace2) { "http://example.com/stockquote2.xsd" }
    let(:xs)         { "http://www.w3.org/2001/XMLSchema"  }

    subject { WSDLParser.new(doc) }

    describe '#endpoint' do
      it 'returns the SOAP 1.2 service endpoint' do
        subject.endpoint.must_equal 'http://example.com/stockquote'
      end
    end

    describe '#types' do
      it 'returns the types, with attributes and namespace' do
        subject.types.must_equal({
          [namespace, 'Price'] => {
            :name       => 'Price',
            :namespace  => namespace,
            :elements   => {},
            :attributes => ['currency']
          },
          [namespace, 'TradePriceRequest'] => {
            :name      => 'TradePriceRequest',
            :namespace => namespace,
            :elements => {
              'accountId' => {
                :name      => 'accountId',
                :namespace => namespace,
                :type      => [xs, "string"],
                :singular  => true
              },
              'tickerSymbol' => {
                :name      => 'tickerSymbol',
                :namespace => namespace,
                :type      => [xs, "string"],
                :singular  => false
              },
              'specialTickerSymbol' => {
                :name      => 'specialTickerSymbol',
                :namespace => namespace,
                :type      => [namespace2, 'TickerSymbol'],
                :singular  => false
              }
            },
            :attributes => ['signature', 'id']
          },
          [namespace, 'HistoricalPriceRequest'] => {
            :name      => 'HistoricalPriceRequest',
            :namespace => namespace,
            :elements => {
              'accountId' => {
                :name      => 'accountId',
                :namespace => namespace,
                :type      => [xs, "string"],
                :singular  => true
              },
              'dateRange' => {
                :name      => 'dateRange',
                :namespace => namespace,
                :type      => {
                  :namespace => namespace,
                  :elements  => {
                    'startDate' => {
                      :name      => 'startDate',
                      :namespace => namespace,
                      :type      => [xs, "string"],
                      :singular  => true
                    },
                    'endDate' => {
                      :name      => 'endDate',
                      :namespace => namespace,
                      :type      => [xs, "string"],
                      :singular  => true
                    }
                  },
                  :attributes => []
                },
                :singular => true
              }
            },
            :attributes => ['signature']
          },
          [namespace2, 'TickerSymbol'] => {
            :name      => 'TickerSymbol',
            :namespace => namespace2,
            :elements  => {
              'name' => {
                :name      => 'name',
                :namespace => nil,
                :type      => [xs, "string"],
                :singular  => true
              }
            },
            :attributes => []
          }
        })
      end
    end

    describe "#abstract_types" do
      it 'returns the abstract types, with attributes and namespace' do
        subject.abstract_types.must_equal({
          [namespace, "BaseRequest"] => {
            :name => "BaseRequest",
            :namespace => "http://example.com/stockquote.xsd",
            :elements => {
              "accountId" => {
                :name => "accountId",
                :namespace => "http://example.com/stockquote.xsd",
                :type => [xs, "string"],
                :singular=>true
              }
            },
            :attributes=>["signature"]
          },
        })
      end
    end

    describe '#elements' do
      it 'returns the elements with inline types' do
        subject.elements.must_equal({
          [namespace, "authentication"] => {
            :name      => "authentication",
            :namespace => namespace,
            :type      => nil
          },
          [namespace, "tradePriceRequestHeader"] => {
            :name      => "tradePriceRequestHeader",
            :namespace => namespace,
            :type      => nil
          },
          [namespace, "tradePriceRequest"] => {
            :name      => "tradePriceRequest",
            :namespace => namespace,
            :type      => [namespace, "TradePriceRequest"]
          },
          [namespace, "TradePrice"] => {
            :name      => "TradePrice",
            :namespace => namespace,
            :type      => {
              :namespace => namespace,
              :elements => {
                'Price' => {
                  :name      => 'Price',
                  :namespace => namespace,
                  :type      => [namespace, 'price'],
                  :singular  => true
                }
              },
              :attributes => []
            }
          },
          [namespace, "specialTickerSymbol"] => {
            :name      => "specialTickerSymbol",
            :namespace => namespace,
            :type      => [namespace2, 'TickerSymbol']
          },
          [namespace, "historicalPriceRequest"] => {
            :name      => "historicalPriceRequest",
            :namespace => namespace,
            :type      => [namespace, "HistoricalPriceRequest"]
          },
          [namespace, "HistoricalPrice"] => {
            :name      => "HistoricalPrice",
            :namespace => namespace,
            :type      => {
              :namespace => namespace,
              :elements => {
                'date' => {
                  :name      => 'date',
                  :namespace => namespace,
                  :type      => [xs, 'date'],
                  :singular  => true
                },
                'price' => {
                  :name      => 'price',
                  :namespace => namespace,
                  :type      => [xs, 'float'],
                  :singular  => true
                }
              },
              :attributes => []
            }
          }
        })
      end
    end

    describe '#messages' do
      it 'maps message names to part names and corresponding types' do
        subject.messages.must_equal({
          'GetLastTradePriceInputHeader' => {
            'header'  => [namespace, 'tradePriceRequestHeader'],
            'header2' => [namespace, 'authentication']
          },
          'GetLastTradePriceInput'       => {
            'foo'  => [xs, 'string'],
            'body' => [namespace, 'tradePriceRequest']
          },
          'GetLastTradePriceOutput'      => {
            'body' => [namespace, 'TradePrice']
          },
          'GetHistoricalPriceInput'      => {
            'body' => [namespace, 'historicalPriceRequest']
          },
          'GetHistoricalPriceOutput'     => {
            'body' => [namespace, 'HistoricalPrice']
          }
        })
      end
    end

    describe '#port_type_operations' do
      it 'maps operations to messages' do
        subject.port_type_operations.must_equal({
          'GetLastTradePrice' => {
            :input  => 'tns:GetLastTradePriceInput',
            :output => 'tns:GetLastTradePriceOutput',
          },
          'GetHistoricalPrice' => {
            :input  => 'tns:GetHistoricalPriceInput',
            :output => 'tns:GetHistoricalPriceOutput'
          }
        })
      end
    end

    describe '#operations' do
      it 'maps operations to actions, input and output parts' do
        subject.operations.must_equal({
          'GetLastTradePrice' => {
            :action => 'http://example.com/GetLastTradePrice',
            :input  => {
              header: [
                [namespace, 'tradePriceRequestHeader'],
                [namespace, 'authentication']
              ],
              body:   [[namespace, 'tradePriceRequest']]
            },
            :output => {
              header: [],
              body:   [[namespace, 'TradePrice']]
            }
          },
          'GetHistoricalPrice' => {
            :action => 'http://example.com/GetHistoricalPrice',
            :input  => {
              header: [],
              body:   [[namespace, 'historicalPriceRequest']]
            },
            :output => {
              header: [],
              body:   [[namespace, 'HistoricalPrice']]
            }
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
