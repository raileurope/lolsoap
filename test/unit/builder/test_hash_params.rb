require 'helper'
require 'lolsoap/builder/hash_params'
require 'pp'

module LolSoap
  describe Builder::HashParams do
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

    subject { Builder::HashParams.new(node, type) }

    def expect_node_added(namespace, args)
      sub_node = MiniTest::Mock.new

      doc.expect(:create_element, sub_node, args)
      sub_node.expect(:namespace=, nil, [namespace])
      node.children.expect(:<<, nil, [sub_node])

      yield sub_node

      [doc, sub_node, node].each(&:verify)
    end

    describe '#content' do
      it 'adds an element to the node, using the correct namespace' do
        expect_node_added(node.namespace_scopes[1], %w[foo bar]) do
          subject.content(foo: 'bar')
        end
      end
    end

    describe '#parse_hash' do
      it 'parses %i[ns name] ' do
        subject.class.send(:public, :parse_hash)
        subject.parse_hash(
          [node.namespace_scopes[1], :foo], 'bar'
        ).must_equal(
          name: 'foo', prefix: node.namespace_scopes[1], args: ['bar']
        )
      end

      it 'parses :name' do
        subject.class.send(:public, :parse_hash)
        subject.parse_hash(:foo, 'bar').must_equal(
          name: 'foo', args: ['bar']
        )
      end

      it 'parses [:name, { attribute: value }]' do
        subject.class.send(:public, :parse_hash)
        subject.parse_hash(
          [:foo, id: 42], 'bar'
        ).must_equal(
          name: 'foo', args: ['bar', { id: 42 }]
        )
      end

      it 'parses [:ns, :name, { attribute: value }]' do
        subject.class.send(:public, :parse_hash)
        subject.parse_hash(
          [node.namespace_scopes[1], :foo, id: 42], 'bar'
        ).must_equal(
          name: 'foo', prefix: node.namespace_scopes[1], args: ['bar', { id: 42 }]
        )
      end

      it 'parses :name, {}' do
        subject.class.send(:public, :parse_hash)
        subject.parse_hash(
          :someTag, foo: 'bar'
        ).must_equal(
          name: 'someTag', sub_hash: { foo: 'bar' }, args: []
        )
      end

      it 'parses :name, -> {}' do
        subject.class.send(:public, :parse_hash)
        block = -> { 'lol' }
        subject.parse_hash(
          :someTag, block
        ).must_equal(
          name: 'someTag', args: [], block: block
        )
      end

    end
  end
end
