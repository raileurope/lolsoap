require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/wsdl'

module LolSoap
  describe Envelope do
    let(:wsdl) { WSDL.parse(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }
    subject { Envelope.new(wsdl, wsdl.operations['GetLastTradePrice']) }

    let(:doc) { subject.doc }

    it 'creates an empty envelope' do
      body = doc.at_xpath('/soap:Envelope/soap:Body/xsd1:TradePriceRequest', doc.namespaces)
      body.wont_equal nil
    end

    it 'creates some input' do
      subject.body do |b|
        b.tickerSymbol 'LOCO2'
        b.specialTickerSymbol do |s|
          s.name 'LOCOLOCOLOCO'
        end
        b.lol
        b.id "42"
      end

      el = doc.at_xpath('//xsd1:TradePriceRequest/xsd1:tickerSymbol', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCO2'

      el = doc.at_xpath('//xsd1:TradePriceRequest/xsd1:specialTickerSymbol/xsd2:name', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCOLOCOLOCO'

      attr = doc.at_xpath('//xsd1:TradePriceRequest/@id', doc.namespaces)
      attr.to_s.must_equal "42"
    end

    it 'creates some header' do
      subject.header do |h|
        h['xsd1'].verySpecialBoolean true
      end

      el = doc.at_xpath('/soap:Envelope/soap:Header/xsd1:verySpecialBoolean', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'true'
    end
  end
end
