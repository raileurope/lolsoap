require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/fault'

module LolSoap
  describe Fault do
    let(:request) { OpenStruct.new(:soap_namespace => Envelope::SOAP_NAMESPACE) }
    let(:node) do
      doc = Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_fault.xml'))
      doc.at_xpath('//soap:Fault', 'soap' => Envelope::SOAP_NAMESPACE)
    end

    subject { Fault.new(request, node) }

    describe '#code' do
      it 'returns the code' do
        subject.code.must_equal 'soap:Sender'
      end
    end

    describe '#reason' do
      it 'returns the reason' do
        subject.reason.must_match /^Omg.*crashed!$/
      end
    end

    describe '#detail' do
      it 'returns the detail' do
        subject.detail.must_equal '<Foo>Some detail</Foo>'
      end
    end
  end
end
