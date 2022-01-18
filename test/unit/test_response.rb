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

    let(:raw_file) { File.read(TEST_ROOT + '/fixtures/stock_quote_response.xml') }
    let(:fault_file) { File.read(TEST_ROOT + '/fixtures/stock_quote_fault.xml') }
    let(:use_ox) { true }

    let(:nokogiri_doc) { Nokogiri::XML(raw_file) }
    let(:doc) {
      if use_ox
        Ox.load(raw_file, { mode: :generic, effort: :strict })
      else
        nokogiri_doc
      end
    }

    subject { Response.new(request, doc, raw_file, use_ox: use_ox) }

    describe '.parse' do
      it 'raises an error if there is invalid XML' do
        if use_ox
          lambda { Response.parse(request, '<a', use_ox: true) }.must_raise Ox::ParseError
        else
          lambda { Response.parse(request, '<a', use_ox: false) }.must_raise Nokogiri::XML::SyntaxError
        end
      end
    end

    describe '#body' do
      it 'returns the first node under the envelope body' do
        # require 'pry'; binding.pry
        # Not sure this is a really sensible test anymore. How do get rid of xpath dependency?
        if use_ox
          # require 'pry'; binding.pry
          subject.body.must_equal nokogiri_doc.at_xpath('/soap:Envelope/soap:Body/m:GetStockPriceResponse')
        else
          subject.body.must_equal doc.at_xpath('/soap:Envelope/soap:Body/m:GetStockPriceResponse')
        end
      end
    end

    describe '#body_hash' do
      it 'builds a hash from the body node' do
        builder = OpenStruct.new(:output => Object.new)
        builder_klass = MiniTest::Mock.new
        # Finding it hard to make this a "unit" test rather than calling ox_body_hash and hence HashBuilderOx
        if use_ox
          builder_klass.expect(:new, builder, [subject.body, request.output_type])
        else
          builder_klass.expect(:new, builder, [subject.body, request.output_type])
        end

        subject.body_hash(builder_klass).must_equal builder.output
      end
    end

    describe '#header' do
      it 'returns the header element' do
        # rubbish test, as they are both nil!!
        # Not sure this is a really sensible test anymore. How do get rid of xpath dependency?
        if use_ox
          subject.header.must_equal nokogiri_doc.at_xpath('/soap:Envelope/soap:Header')
        else
          subject.header.must_equal doc.at_xpath('/soap:Envelope/soap:Header')
        end
      end
    end

    it 'should return the soap fault' do
      response = Response.new(
        request,
        use_ox ? Ox.load(fault_file, { mode: :generic, effort: :strict }) : Nokogiri::XML(fault_file),
        fault_file,
        use_ox: use_ox
      )
      response.fault.wont_equal nil
    end
  end
end
