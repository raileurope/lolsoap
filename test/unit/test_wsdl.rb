require 'helper'
require 'lolsoap/wsdl'
require 'ostruct'

module LolSoap
  describe WSDL do
    describe 'with a doc that can be parsed' do
      subject { WSDL.new(nil) }

      let(:namespace) { 'http://lolsoap.api/bla' }

      let(:parser) do
        OpenStruct.new(
          :endpoint => 'http://lolsoap.api/v1',
          :operations => {
            :wash_hands => {
              :action => "urn:washHands",
              :input  => "washHands"
            }
          },
          :namespaces => {
            'bla' => namespace
          },
          :types => {
            'Brush' => {
              'handleColor' => { :type => 'bla:Color' },
              'age'         => { :type => 'xs:int' },
              :namespace => namespace
            },
            'Color' => {
              'name' => { :type => 'xs:string' },
              'hex'  => { :type => 'xs:string' },
              :namespace => namespace
            }
          }
        )
      end

      before do
        subject.parser = parser
      end

      describe '#operations' do
        it 'returns a hash of operations' do
          subject.operations.length.must_equal 1
          subject.operations['washHands'].tap do |op|
            op.wsdl.must_equal   subject
            op.action.must_equal "urn:washHands"
            op.input.must_equal  "washHands"
          end
        end
      end

      describe '#endpoint' do
        it 'returns the endpoint' do
          subject.endpoint.must_equal 'http://lolsoap.api/v1'
        end
      end

      describe '#namespaces' do
        it 'returns a namespaces hash' do
          subject.namespaces.must_equal parser.namespaces
        end
      end

      describe '#types' do
        it 'returns a hash of types' do
          subject.types.length.must_equal 2

          subject.types['Brush'].tap do |t|
            t.wsdl.must_equal subject
            t.namespace.must_equal namespace
            t.elements.length.must_equal 2
            t.elements['handleColor'].must_equal subject.types['Color']
            t.elements['age'].must_be_nil
          end

          subject.types['Color'].tap do |t|
            t.wsdl.must_equal subject
            t.namespace.must_equal namespace
            t.elements.length.must_equal 2
            t.elements['name'].must_be_nil
            t.elements['hex'].must_be_nil
          end
        end
      end
    end
  end
end
