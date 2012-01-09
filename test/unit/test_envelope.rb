require 'helper'
require 'lolsoap/envelope'

module LolSoap
  describe Envelope do
    describe 'when first created' do
      let(:wsdl) { OpenStruct.new(:namespaces => { 'foo' => 'http://example.com/foo' }) }
      let(:operation) do
        OpenStruct.new(:input_prefix => 'foo', :input_name => 'WashHandsRequest')
      end

      subject { LolSoap::Envelope.new(wsdl, operation) }

      it 'has a skeleton SOAP envelope structure' do
        doc = subject.doc
        doc.namespaces.must_equal(
          'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
          'xmlns:foo'  => 'http://example.com/foo'
        )

        header = doc.at_xpath('/soap:Envelope/soap:Header', doc.namespaces)
        header.wont_equal nil
        header.children.length.must_equal 0

        body = doc.at_xpath('/soap:Envelope/soap:Body/foo:WashHandsRequest', doc.namespaces)
        body.wont_equal nil
        body.children.length.must_equal 0
      end
    end
  end
end
