require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/response'

module LolSoap
  describe Response do
    let(:request) {
      OpenStruct.new(
        :soap_namespace => Envelope::SOAP_1_2,
        :soap_version   => '1.2',
        :output_type    => Object.new
      )
    }

    let(:doc) { Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_response.xml')) }

    subject { Response.new(request, doc) }

    describe '.parse' do
      it 'raises an error if there is invalid XML' do
        lambda { Response.parse(request, '<a') }.must_raise Nokogiri::XML::SyntaxError
      end
    end

    describe '#body' do
      it 'returns the first node under the envelope body' do
        subject.body.must_equal doc.at_xpath('/soap:Envelope/soap:Body/m:GetStockPriceResponse')
      end
    end

    describe '#body_hash' do
      it 'builds a hash from the body node' do
        builder = OpenStruct.new(:output => Object.new)
        builder_klass = MiniTest::Mock.new
        builder_klass.expect(:new, builder, [subject.body, request.output_type])

        subject.body_hash(builder_klass).must_equal builder.output
      end
    end

    describe '#header' do
      it 'returns the header element' do
        subject.header.must_equal doc.at_xpath('/soap:Envelope/soap:Header')
      end
    end

    it 'should return the soap fault' do
      response = Response.new(request, Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_fault.xml')))
      response.fault.wont_equal nil
    end
  end
end
