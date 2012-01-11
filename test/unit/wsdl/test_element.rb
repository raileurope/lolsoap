require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Element do
    let(:wsdl) { OpenStruct.new }
    subject { Element.new(wsdl, 'foo', 'a:WashHandsRequest', true) }

    describe '#type' do
      let(:wsdl) { MiniTest::Mock.new }

      it 'ignores the namespace and gets the type from the wsdl' do
        type = Object.new
        wsdl.expect(:type, type, ['WashHandsRequest'])
        subject.type.must_equal type
      end
    end

    describe '#singular?' do
      it 'returns the singular value' do
        subject.singular?.must_equal true
      end
    end

    describe '#inspect' do
      it 'works' do
        subject.inspect
      end
    end
  end
end
