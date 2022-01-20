require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/fault_ox'

module LolSoap
  describe FaultOx do
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
          subject.detail.strip.must_equal '<Foo>Some detail</Foo>'
        end
      end

      describe '#at' do
        it 'returns the well hidden info' do
          subject.at('WellHidden').text.must_equal 'Secret hidden info'
        end
      end
    end

    describe 'SOAP 1.2' do
      let(:request) { OpenStruct.new(soap_version: '1.2', soap_namespace: Envelope::SOAP_1_2) }
      let(:node) do
        doc = Ox.load(File.read("#{TEST_ROOT}/fixtures/stock_quote_fault.xml"))
        doc.locate('soap:Envelope/soap:Body/soap:Fault').first
      end

      subject { FaultOx.new(request, node) }

      instance_eval(&examples)
    end

    describe 'SOAP 1.1' do
      let(:request) { OpenStruct.new(soap_version: '1.1', soap_namespace: Envelope::SOAP_1_1) }
      let(:node) do
        doc = Ox.load(File.read("#{TEST_ROOT}/fixtures/stock_quote_fault_soap_1_1.xml"))
        doc.locate('soap:Envelope/soap:Body/soap:Fault').first
      end

      subject { FaultOx.new(request, node) }

      instance_eval(&examples)
    end
  end
end
