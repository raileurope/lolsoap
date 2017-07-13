require 'helper'
require 'lolsoap/builder/hash_params'
require 'pp'
require 'awesome_print'

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

    describe '#parse' do
      it 'adds an element to the node, using the correct namespace' do
        expect_node_added(node.namespace_scopes[1], %w[foo bar]) do
          subject.parse(foo: 'bar')
        end
      end
    end

    describe '#extract_params!' do
      it 'extracts' do
        subject.class.send(:public, :extract_params!)
        subject.extract_params!(
          type, {
            ns: node.namespace_scopes[1],
            tag: 'foo'
          }, 'bar'
        ).must_equal(
          name: 'foo', prefix: node.namespace_scopes[1], attributes: {},
          sub_hash: nil, content: 'bar', sub_type: type.sub_type('foo')
        )
      end
    end
  end
end
