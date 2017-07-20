require 'helper'
require 'lolsoap/builder'
require 'pp'

module LolSoap
  describe Builder do
    let(:type) { MiniTest::Mock.new }
    let(:node) { MiniTest::Mock.new }

    it 'sets the builder to HashParams' do
      builder = Builder.new(node, type).tap do |b|
        def b.content(*)
          true
        end
      end
      builder.content(Say: 'lol')
      builder.__getobj__.must_be_kind_of LolSoap::Builder::HashParams
    end

    it 'sets the builder to block' do
      builder = Builder.new(node, type) do |b|
        def b.method_missing(*)
          true
        end
        b.say 'lol'
      end
      builder.__getobj__.must_be_kind_of LolSoap::Builder::BlockParams
    end

    it 'sets the builder default to HashParams' do
      Builder.new(node, type).__getobj__.must_be_kind_of LolSoap::Builder::HashParams
    end
  end
end
