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
          def subject.type(n)
            @types ||= { 'WashHandsRequest' => Object.new, 'WashHandsResponse' => Object.new }
            @types[n]
          end

          parser.operations = {
            'washHands' => {
              :action => 'urn:washHands',
              :input  => { :name => 'WashHandsRequest' },
              :output => { :name => 'WashHandsResponse' }
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
              op.output.must_equal subject.types['WashHandsResponse']
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
                'handleColor' => {
                  :name     => 'handleColor',
                  :type     => 'bla:Color',
                  :singular => true
                },
                'age' => {
                  :name     => 'age',
                  :type     => 'xs:int',
                  :singular => false
                }
              },
              :namespace => namespace
            },
            'Color' => {
              :elements => {
                'name' => {
                  :name     => 'name',
                  :type     => 'xs:string',
                  :singular => true
                },
                'hex' => {
                  :name     => 'hex',
                  :type     => 'xs:string',
                  :singular => true
                }
              },
              :namespace => namespace
            }
          }
        end

        describe '#types' do
          it 'returns a hash of types' do
            subject.types.length.must_equal 2

            subject.types['Brush'].tap do |t|
              t.namespace.must_equal namespace
              t.elements.length.must_equal 2
              t.element('handleColor').type.must_equal subject.types['Color']
              t.element('handleColor').singular?.must_equal true
              t.element('age').type.must_equal WSDL::NullType.new
              t.element('age').singular?.must_equal false
            end

            subject.types['Color'].tap do |t|
              t.namespace.must_equal namespace
              t.elements.length.must_equal 2
              t.element('name').type.must_equal WSDL::NullType.new
              t.element('hex').type.must_equal WSDL::NullType.new
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

        describe '#type_namespaces' do
          it 'returns only the namespaces that used by types' do
            parser.namespaces['foo'] = 'bar'
            subject.type_namespaces.must_equal 'bla' => namespace
          end
        end
      end
    end
  end
end
