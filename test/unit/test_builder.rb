require 'helper'
require 'lolsoap/builder'

module LolSoap
  describe Builder do
    let(:doc) { MiniTest::Mock.new }
    let(:node) do
      node = OpenStruct.new(
        :document         => doc,
        :namespace_scopes => [OpenStruct.new(:prefix => 'b'), OpenStruct.new(:prefix => 'a')],
        :children         => MiniTest::Mock.new
      )
      def node.<<(child); children << child; end
      node
    end
    let(:type) do
      type = Object.new
      def type.element(name)
        elements ||= { 'foo' => OpenStruct.new(:prefix => 'a'), 'bar' => OpenStruct.new(:prefix => nil),
                       'clone' => OpenStruct.new(:prefix => nil) }
        elements[name]
      end
      type
    end

    subject { Builder.new(node, type) }

    def expect_node_added(namespace, *args)
      sub_node = MiniTest::Mock.new

      doc.expect(:create_element, sub_node, args)
      sub_node.expect(:namespace=, nil, [namespace])
      node.children.expect(:<<, nil, [sub_node])

      yield sub_node

      [doc, sub_node, node].each(&:verify)
    end

    describe '#__tag__' do
      it 'adds an element to the node, using the correct namespace' do
        expect_node_added node.namespace_scopes[1], 'foo', 'bar' do |sub_node|
          sub_builder = subject.__tag__(:foo, 'bar')
          sub_builder.__node__.object_id.must_equal sub_node.object_id
          sub_builder.__type__.must_equal type.element('foo')
        end
      end

      it 'adds the element with no prefix if the type is unknown' do
        expect_node_added nil, 'bar' do
          subject.__tag__(:bar)
        end
      end


      it 'yields to a block, if given' do
        expect_node_added nil, 'bar' do
          block = nil
          ret = subject.__tag__(:bar) { |b| block = b }
          block.object_id.must_equal ret.object_id
        end
      end
    end

    describe 'method missing' do
      it 'delegates to __tag__' do
        expect_node_added nil, 'bar', 'baz' do
          subject.bar 'baz'
        end
      end

      it 'supports standard methods that are usually defined' do
        expect_node_added nil, 'clone' do
          subject.clone
        end
      end
    end

    it 'responds to anything' do
      subject.respond_to?('omgwtfbbq').must_equal true
      subject['b'].respond_to?('omgwtfbbq').must_equal true
    end

    it 'can add elements with a custom prefix' do
      expect_node_added node.namespace_scopes[0], 'foo' do
        subject['b'].foo
      end
    end

    describe '#__node__' do
      it 'returns the node' do
        subject.__node__.must_equal node
      end
    end

    describe '#__type__' do
      it 'returns the type' do
        subject.__type__.must_equal type
      end
    end

  end
end
