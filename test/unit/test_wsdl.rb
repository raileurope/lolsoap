require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    describe 'with a doc that can be parsed' do
      let(:namespace) { 'http://lolsoap.api/bla' }
      let(:parser) { OpenStruct.new(:namespaces => { 'bla' => namespace }) }

      subject { WSDL.new(parser) }

      describe '#operations' do
        it 'returns a hash of operations' do
          def subject.types; @types ||= { 'WashHandsRequest' => Object.new }; end
          parser.operations = {
            'washHands' => {
              :action => 'urn:washHands',
              :input  => { :name => 'WashHandsRequest' }
            }
          }

          subject.operations.length.must_equal 1
          subject.operations['washHands'].tap do |op|
            op.wsdl.must_equal   subject
            op.action.must_equal "urn:washHands"
            op.input.must_equal  subject.types['WashHandsRequest']
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

      describe '#types' do
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
