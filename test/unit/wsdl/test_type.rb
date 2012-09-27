require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Type do
    let(:elements) { { 'soapColor' => OpenStruct.new(:type => Object.new) } }

    subject { Type.new('WashHandsRequest', 'prfx', elements, {}) }

    describe '#prefix' do
      it 'returns the prefix' do
        subject.prefix.must_equal 'prfx'
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

    describe '#inspect' do
      it 'works' do
        subject.inspect
      end
    end
  end
end
