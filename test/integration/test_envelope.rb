require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/wsdl'

module LolSoap
  describe Envelope do
    let(:wsdl) { WSDL.parse(File.read(TEST_ROOT + '/fixtures/stock_quote.wsdl')) }
    subject { Envelope.new(wsdl, wsdl.operations['GetLastTradePrice']) }

    let(:doc) { subject.doc }

    it 'creates an empty envelope' do
      body = doc.at_xpath('/soap:Envelope/soap:Body/ns0:tradePriceRequest', doc.namespaces)
      body.wont_equal nil
    end

    it 'creates some input' do
      subject.body do |b|
        b.tickerSymbol 'LOCO2'
        b.specialTickerSymbol do |s|
          s.name 'LOCOLOCOLOCO'
        end
        b.lol
        b.id 42
      end

      el = doc.at_xpath('//ns0:tradePriceRequest/ns0:tickerSymbol', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCO2'

      el = doc.at_xpath('//ns0:tradePriceRequest/ns0:specialTickerSymbol/ns1:name', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCOLOCOLOCO'

      attr = doc.at_xpath('//ns0:tradePriceRequest/@id', doc.namespaces)
      attr.to_s.must_equal "42"
    end

    it 'creates some input from hash' do
      subject.body.content(
        tickerSymbol: 'LOCO2',
        specialTickerSymbol: {
          name: 'LOCOLOCOLOCO'
        },
        lol: nil
      )
      subject.body.attributes(id: 42)
      el = doc.at_xpath('//ns0:tradePriceRequest/ns0:tickerSymbol', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCO2'

      el = doc.at_xpath('//ns0:tradePriceRequest/ns0:specialTickerSymbol/ns1:name', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCOLOCOLOCO'

      attr = doc.at_xpath('//ns0:tradePriceRequest/@id', doc.namespaces)
      attr.to_s.must_equal '42'
    end

    it 'creates some input from hash containing block' do
      subject.body.content(
        tickerSymbol: 'LOCO2',
        specialTickerSymbol: ->(s) { s.name 'LOCOLOCOLOCO' },
        lol: nil
      )
      subject.body.attributes(id: 42)
      el = doc.at_xpath('//ns0:tradePriceRequest/ns0:tickerSymbol', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCO2'

      el = doc.at_xpath('//ns0:tradePriceRequest/ns0:specialTickerSymbol/ns1:name', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCOLOCOLOCO'

      attr = doc.at_xpath('//ns0:tradePriceRequest/@id', doc.namespaces)
      attr.to_s.must_equal '42'
    end

    it 'creates some header' do
      subject.header do |header|
        header.authentication do |auth|
          auth['ns0'].username 'LOCO2'
        end
      end

      el = doc.at_xpath('/soap:Envelope/soap:Header/ns0:authentication/ns0:username', doc.namespaces)
      el.wont_equal nil
      el.text.to_s.must_equal 'LOCO2'
    end
  end
end
