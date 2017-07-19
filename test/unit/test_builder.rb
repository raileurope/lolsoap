require 'helper'
require 'lolsoap/builder'
require 'pp'

module LolSoap
  describe Builder do
    let(:type) do 
      m = MiniTest::Mock.new
      m.expect(:has_attribute?, false, [String])
      m.expect(:element_prefix, 'ns', [String])
      m.expect(:sub_type, nil, [String])
      m
    end
    
    let(:node) do
      doc = MiniTest::Mock.new
      doc.expect(:create_element, doc, [String, String])
      n = OpenStruct.new(
        document: doc
      )
      def n.<<(child); children << child; end
      n
    end

    it 'sets the builder to HashParams' do
      skip
      builder = Builder.new(node, type)
      builder.content(Say: 'lol')
      builder.__getobj__.must_be_kind_of LolSoap::Builder::HashParams
    end

    it 'sets the builder to block' do
      skip
      builder = Builder.new(node, type) do |b|
        b.Say 'lol'
      end
      builder.__getobj__.must_be_kind_of LolSoap::Builder::BlockParams
    end

    it 'sets the builder default to HashParams' do
      Builder.new(node, type).__getobj__.must_be_kind_of LolSoap::Builder::HashParams
    end
  end
end