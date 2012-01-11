require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Type do
    let(:wsdl) { OpenStruct.new(:prefixes => { 'http://example.com/foo' => 'foo' }) }
    let(:elements) { { 'soapColor' => OpenStruct.new(:type => Object.new) } }
    subject { Type.new(wsdl, 'WashHandsRequest', 'http://example.com/foo', elements) }

    describe '#prefix' do
      it 'returns the prefix from the WSDL doc' do
        subject.prefix.must_equal 'foo'
      end
    end

    describe '#elements' do
      it 'returns a hash of all elements' do
        subject.elements.must_equal(elements)
      end
    end

    describe '#element' do
      it 'returns a specific element' do
        subject.element('soapColor').must_equal elements['soapColor']
      end

      it 'returns a null object when there is no element' do
        subject.element('lol').must_equal NullElement.new
      end
    end

    describe '#sub_type' do
      it 'returns the type of a specific element' do
        subject.sub_type('soapColor').must_equal elements['soapColor'].type
      end
    end
  end
end
