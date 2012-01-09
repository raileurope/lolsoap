require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Type do
    let(:wsdl) do
      OpenStruct.new(
        :prefixes => { 'http://example.com/foo' => 'foo' },
        :types    => { 'Color' => Object.new }
      )
    end
    subject { Type.new(wsdl, 'WashHandsRequest', 'http://example.com/foo', { 'soapColor' => 'Color' }) }

    describe '#prefix' do
      it 'returns the prefix from the WSDL doc' do
        subject.prefix.must_equal 'foo'
      end
    end

    describe '#elements' do
      it 'returns a hash of all elements' do
        subject.elements.must_equal({ 'soapColor' => wsdl.types['Color'] })
      end
    end

    describe '#element' do
      it 'returns a specific element' do
        subject.element('soapColor').must_equal wsdl.types['Color']
      end

      it 'returns a null object if the element does not exit' do
        subject.element('omg').is_a?(NullType).must_equal true
      end
    end
  end
end
