require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Element do
    let(:wsdl)           { MiniTest::Mock.new }
    let(:type_reference) { MiniTest::Mock.new }
    let(:type)           { Object.new }

    subject { Element.new(wsdl, 'bar', 'foo', type_reference, true) }

    before do
      type_reference.expect(:type, type)
    end

    describe '#type' do
      it 'returns the type via the reference' do
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
