require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    describe 'with a doc that can be parsed' do
      let(:namespace) { 'http://lolsoap.api/bla' }

      let(:parser) do
        OpenStruct.new(
          :namespaces => { 'bla' => namespace },
          :operations => {
            'washHands' => {
              :action => 'urn:washHands',
              :input  => 'bla:Brush',
              :output => 'bla:Color'
            }
          },
          :types => {
            'bla:Brush' => {
              :elements => {
                'handleColor' => {
                  :type     => 'bla:Color',
                  :singular => true
                },
                'age' => {
                  :type     => 'xs:int',
                  :singular => false
                }
              },
              :attributes => ['id'],
              :prefix => 'bla'
            },
            'bla:Color' => {
              :elements => {
                'name' => {
                  :type     => 'xs:string',
                  :singular => true
                },
                'hex' => {
                  :type     => 'xs:string',
                  :singular => true
                }
              },
              :attributes => [],
              :prefix => 'bla'
            }
          }
        )
      end

      subject { WSDL.new(parser) }

      describe '#operations' do
        it 'returns a hash of operations' do
          subject.operations.length.must_equal 1
          subject.operations['washHands'].tap do |op|
            op.wsdl.must_equal   subject
            op.action.must_equal "urn:washHands"
            op.input.must_equal  subject.types['bla:Brush']
            op.output.must_equal subject.types['bla:Color']
          end
        end
      end

      describe '#operation' do
        it 'returns a single operation' do
          subject.operation('washHands').must_equal subject.operations['washHands']
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

      describe '#types' do
        it 'returns a hash of types' do
          subject.types.length.must_equal 2

          subject.types['bla:Brush'].tap do |t|
            t.elements.length.must_equal 2
            t.element('handleColor').type.must_equal subject.types['bla:Color']
            t.element('handleColor').singular?.must_equal true
            t.element('age').type.must_equal WSDL::NullType.new
            t.element('age').singular?.must_equal false
            t.attributes.must_equal ['id']
          end

          subject.types['bla:Color'].tap do |t|
            t.elements.length.must_equal 2
            t.element('name').type.must_equal WSDL::NullType.new
            t.element('hex').type.must_equal WSDL::NullType.new
          end
        end
      end

      describe '#type' do
        it 'returns a single type' do
          subject.type('bla:Color').must_equal subject.types['bla:Color']
        end

        it 'returns a null object if a type is missing' do
          subject.type('FooBar').must_equal WSDL::NullType.new
        end
      end

      describe '#type_namespaces' do
        it 'returns only the namespaces that are used by types' do
          parser.namespaces['foo'] = 'bar'
          subject.type_namespaces.must_equal 'bla' => namespace
        end
      end
    end
  end
end
