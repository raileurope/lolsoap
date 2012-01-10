require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    describe 'with a doc that can be parsed' do
      let(:namespace) { 'http://lolsoap.api/bla' }
      let(:parser) { OpenStruct.new(:namespaces => { 'bla' => namespace }) }

      subject { WSDL.new(parser) }

      describe 'with operations' do
        before do
          def subject.type(n); @types ||= { 'WashHandsRequest' => Object.new }; @types[n] end
          parser.operations = {
            'washHands' => {
              :action => 'urn:washHands',
              :input  => { :name => 'WashHandsRequest' }
            }
          }
        end

        describe '#operations' do
          it 'returns a hash of operations' do
            subject.operations.length.must_equal 1
            subject.operations['washHands'].tap do |op|
              op.wsdl.must_equal   subject
              op.action.must_equal "urn:washHands"
              op.input.must_equal  subject.types['WashHandsRequest']
            end
          end
        end

        describe '#operation' do
          it 'returns a single operation' do
            subject.operation('washHands').must_equal subject.operations['washHands']
          end
        end
      end

      describe '#endpoint' do
        it 'returns the endpoint' do
          parser.endpoint = 'http://lolsoap.api/v1'
          subject.endpoint.must_equal 'http://lolsoap.api/v1'
        end
      end

      describe '#namespaces' do
        it 'returns a namespaces hash' do
          subject.namespaces.must_equal({ 'bla' => namespace })
        end
      end

      describe '#prefixes' do
        it 'returns the prefixes-to-namespace mapping' do
          subject.prefixes.must_equal({ namespace => 'bla' })
        end
      end

      describe 'with types' do
        before do
          parser.types = {
            'Brush' => {
              :elements => {
                'handleColor' => 'bla:Color',
                'age'         => 'xs:int'
              },
              :namespace => namespace
            },
            'Color' => {
              :elements => {
                'name' => 'xs:string',
                'hex'  => 'xs:string'
              },
              :namespace => namespace
            }
          }
        end

        describe '#types' do
          it 'returns a hash of types' do
            subject.types.length.must_equal 2

            subject.types['Brush'].tap do |t|
              t.wsdl.must_equal subject
              t.namespace.must_equal namespace
              t.elements.length.must_equal 2
              t.elements['handleColor'].must_equal subject.types['Color']
              t.elements['age'].must_equal WSDL::NullType.new
            end

            subject.types['Color'].tap do |t|
              t.wsdl.must_equal subject
              t.namespace.must_equal namespace
              t.elements.length.must_equal 2
              t.elements['name'].must_equal WSDL::NullType.new
              t.elements['hex'].must_equal WSDL::NullType.new
            end
          end
        end

        describe '#type' do
          it 'returns a single type' do
            subject.type('Color').must_equal subject.types['Color']
          end

          it 'returns a null object if a type is missing' do
            subject.type('FooBar').must_equal WSDL::NullType.new
          end
        end
      end
    end
  end
end
