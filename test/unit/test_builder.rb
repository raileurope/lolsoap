require 'helper'
require 'lolsoap/builder'
require 'pp'

module LolSoap
  describe Builder do
    let(:doc) { MiniTest::Mock.new }
    let(:node) do
      n = OpenStruct.new(
        :document         => doc,
        :namespace_scopes => [OpenStruct.new(:prefix => 'b'), OpenStruct.new(:prefix => 'a')],
        :children         => MiniTest::Mock.new
      )
      def n.<<(child); children << child; end
      n
    end
    let(:type) do
      t = OpenStruct.new(:prefix => 'a')
      def t.element_prefix(name)
        @element_prefixes = { 'bar' => 'b' }
        @element_prefixes.fetch(name) { 'a' }
      end
      def t.has_attribute?(*); false; end
      def t.sub_type(name)
        @sub_types ||= { 'foo' => Object.new, 'bar' => Object.new, 'clone' => Object.new }
        @sub_types[name]
      end
      t
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
          sub_builder.__type__.must_equal type.sub_type('foo')
        end
      end

      it 'yields to a block, if given' do
        expect_node_added node.namespace_scopes[0], 'bar' do
          block = nil
          ret = subject.__tag__(:bar) { |b| block = b }
          block.object_id.must_equal ret.object_id
        end
      end
    end

    describe 'method missing' do
      it 'delegates to __tag__' do
        expect_node_added node.namespace_scopes[0], 'bar', 'baz' do
          subject.bar 'baz'
        end
      end

      it 'supports standard methods that are usually defined' do
        expect_node_added node.namespace_scopes[1], 'clone' do
          subject.clone
        end
      end

      it 'sets content' do
        subject.__content__ 'zomg'
        node.content.must_equal 'zomg'
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

    it 'can be pretty printed' do
      output = ''
      PP.pp(subject, output)
      output.include?("LolSoap::Builder").must_equal true
    end
  end
end
