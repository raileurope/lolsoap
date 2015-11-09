require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    describe 'with a doc that can be parsed' do
      let(:namespace) { 'http://lolsoap.api/bla' }
      let(:xs)        { "http://www.w3.org/2001/XMLSchema" }

      let(:parser) do
        OpenStruct.new(
          :namespaces => { 'bla' => namespace },
          :operations => {
            'washHands' => {
              :action => 'urn:washHands',
              :input  => {
                :header => [],
                :body   => [[namespace, 'brush']]
              },
              :output => {
                :header => [],
                :body   => [[namespace, 'Color']]
              }
            }
          },
          :types => {
            [namespace, 'Brush'] => {
              :name => 'Brush',
              :elements => {
                'handleColor' => {
                  :name      => 'handleColor',
                  :namespace => namespace,
                  :type      => {
                    :elements => {
                      'name' => {
                        :name      => 'name',
                        :namespace => namespace,
                        :singular  => true
                      },
                      'hex' => {
                        :name      => 'hex',
                        :namespace => namespace,
                        :type      => [xs, "string"],
                        :singular  => true
                      }
                    },
                    :namespace  => namespace,
                    :attributes => []
                  },
                  :singular => true
                },
                'age' => {
                  :name      => 'age',
                  :namespace => namespace,
                  :type      => [xs, "int"],
                  :singular  => false
                }
              },
              :attributes => ['id'],
              :namespace  => namespace
            }
         },
         :elements => {
            [namespace, 'brush'] => {
              :name      => 'brush',
              :namespace => namespace,
              :type      => [namespace, 'Brush']
            },
            [namespace, 'Color'] => {
              :name      => 'Color',
              :namespace => namespace,
              :type      => {
                :elements => {
                  'name' => {
                    :name      => 'name',
                    :namespace => namespace,
                    :type      => [xs, "string"],
                    :singular  => true
                  },
                  'hex' => {
                    :name      => 'hex',
                    :namespace => namespace,
                    :type      => [xs, "string"],
                    :singular  => true
                  }
                },
                :namespace  => namespace,
                :attributes => []
              }
            }
          }
        )
      end

      subject { WSDL.new(parser) }

      describe '#operations' do
        it 'returns a hash of operations' do
          subject.operations.length.must_equal 1
          subject.operations['washHands'].tap do |op|
            op.wsdl.must_equal subject
            op.action.must_equal 'urn:washHands'

            op.input.header.tap do |header|
              header.is_a?(WSDL::OperationIOPart).must_equal(true)
              header.name.must_equal 'Header'
              header.content.must_equal nil
            end

            op.input.body.tap do |body|
              body.is_a?(WSDL::OperationIOPart).must_equal(true)
              body.name.must_equal 'Body'
              body.content.is_a?(WSDL::Element).must_equal(true)
              body.content.name.must_equal 'brush'
            end

            op.output.header.tap do |header|
              header.is_a?(WSDL::OperationIOPart).must_equal(true)
              header.name.must_equal 'Header'
              header.content.must_equal nil
            end

            op.output.body.tap do |body|
              body.is_a?(WSDL::OperationIOPart).must_equal(true)
              body.name.must_equal 'Body'

              body.content.tap do |content|
                content.is_a?(WSDL::Element).must_equal(true)
                content.name.must_equal 'Color'
                content.type.elements.keys.sort.must_equal %w(hex name)
              end
            end
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
          subject.namespaces.must_equal({ 'ns0' => namespace })
        end
      end

      describe '#types' do
        it 'returns a hash of types' do
          subject.types.length.must_equal 1

          subject.types['Brush'].tap do |t|
            t.elements.length.must_equal 2
            t.element('handleColor').type.tap do |type|
              type.is_a?(WSDL::Type).must_equal true
              type.elements.keys.sort.must_equal %w(hex name)
            end
            t.element('handleColor').prefix.must_equal 'ns0'
            t.element('handleColor').singular?.must_equal true
            t.element('age').type.must_equal WSDL::NullType.new
            t.element('age').singular?.must_equal false
            t.attributes.must_equal ['id']
          end
        end
      end

      describe '#type' do
        it 'returns a single type' do
          subject.type(namespace, 'Brush').must_equal subject.types.fetch('Brush')
        end

        it 'returns a null object if a type is missing' do
          subject.type(namespace, 'FooBar').must_equal WSDL::NullType.new
        end
      end
    end
  end
end
