require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/response'

module LolSoap
  describe Response do
    let(:request) { OpenStruct.new(:soap_namespace => Envelope::SOAP_NAMESPACE) }
    let(:doc) { Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_response.xml')) }

    subject { Response.new(request, doc) }

    describe '#body' do
      it 'returns the first node under the envelope body' do
        subject.body.must_equal doc.at_xpath('/soap:Envelope/soap:Body/m:GetStockPriceResponse')
      end
    end

    describe '#header' do
      it 'returns the header element' do
        subject.header.must_equal doc.at_xpath('/soap:Envelope/soap:Header')
      end
    end

    it 'should raise a FaultRaised error when initialized, if there is a SOAP fault' do
      lambda { Response.new(request, Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_fault.xml'))) }.
        must_raise FaultRaised
    end
  end
end
