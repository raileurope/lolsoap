require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Type do
    let(:wsdl) do
      wsdl = OpenStruct.new(:prefixes => { 'http://example.com/foo' => 'foo' })
      def wsdl.type(name); @types ||= { 'Color' => Object.new }; @types[name]; end
      wsdl
    end
    subject { Type.new(wsdl, 'WashHandsRequest', 'http://example.com/foo', { 'soapColor' => 'Color' }) }

    describe '#prefix' do
      it 'returns the prefix from the WSDL doc' do
        subject.prefix.must_equal 'foo'
      end
    end

    describe '#elements' do
      it 'returns a hash of all elements' do
        subject.elements.must_equal({ 'soapColor' => wsdl.type('Color') })
      end
    end

    describe '#element' do
      it 'returns a specific element' do
        subject.element('soapColor').must_equal wsdl.type('Color')
      end

      it 'returns a null object if the element does not exit' do
        subject.element('omg').must_equal NullType.new
      end
    end
  end
end
