require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/fault'

module LolSoap
  describe Fault do
    examples = proc do
      describe '#code' do
        it 'returns the code' do
          subject.code.must_equal 'soap:Sender'
        end
      end

      describe '#reason' do
        it 'returns the reason' do
          subject.reason.must_match(/^Omg.*crashed!$/)
        end
      end

      describe '#detail' do
        it 'returns the detail' do
          subject.detail.must_equal '<Foo>Some detail</Foo>'
        end
      end
    end

    describe 'SOAP 1.2' do
      let(:request) { OpenStruct.new(:soap_version => '1.2', :soap_namespace => Envelope::SOAP_1_2) }
      let(:node) do
        doc = Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_fault.xml'))
        doc.at_xpath('//soap:Fault', 'soap' => Envelope::SOAP_1_2)
      end

      subject { Fault.new(request, node) }

      instance_eval(&examples)
    end

    describe 'SOAP 1.1' do
      let(:request) { OpenStruct.new(:soap_version => '1.1', :soap_namespace => Envelope::SOAP_1_1) }
      let(:node) do
        doc = Nokogiri::XML(File.read(TEST_ROOT + '/fixtures/stock_quote_fault_soap_1_1.xml'))
        doc.at_xpath('//soap:Fault', 'soap' => Envelope::SOAP_1_1)
      end

      subject { Fault.new(request, node) }

      instance_eval(&examples)
    end
  end
end
