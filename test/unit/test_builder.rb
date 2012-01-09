require 'helper'
require 'lolsoap/builder'

module LolSoap
  describe Builder do
    let(:node) { MiniTest::Mock.new }
    let(:type) do
      type = Object.new
      def type.element(name)
        elements ||= { 'foo' => OpenStruct.new(:prefix => 'a'), 'bar' => OpenStruct.new(:prefix => nil) }
        elements[name]
      end
      type
    end

    subject { Builder.new(node, type) }

    describe '#__tag__' do
      it 'adds an element to the node, using the correct namespace prefix' do
        sub_node = Object.new
        prefix   = MiniTest::Mock.new

        node.expect(:[], prefix, ['a'])
        prefix.expect(:foo, sub_node, ['bar'])

        sub_builder = subject.__tag__(:foo, 'bar')
        sub_builder.node.must_equal sub_node
        sub_builder.type.must_equal type.element('foo')

        prefix.verify
        node.verify
      end

      it 'adds the element with no prefix if the type is unknown' do
        node.expect(:bar, nil)
        subject.__tag__(:bar)
        node.verify
      end

      it 'yields to a block, if given' do
        sub_node = Object.new
        node.expect(:bar, sub_node)

        block = nil
        ret = subject.__tag__(:bar) { |b| block = b }

        block.must_equal ret
      end
    end

    describe 'method missing' do
      it 'delegates to __tag__' do
        node.expect(:bar, nil, ['baz'])
        subject.bar 'baz'
        node.verify
      end
    end
  end
end
