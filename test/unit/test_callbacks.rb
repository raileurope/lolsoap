require 'helper'
require 'lolsoap/callbacks.rb'

module LolSoap
  describe Callbacks do
    before do
      Callbacks.register([
        {"a.b" => ->(name, mutable) { mutable << "Before #{name}" }},
      ])
    end

    it 'can store one callback' do
      Callbacks.store.size.must_equal 1
    end

    it 'can call a callback' do
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Before lol']
    end

    it 'can call a callback normal' do
      ary = []

      Callbacks.register([
        {"a.b" => ->(name, mutable) { mutable << "Normal #{name}" }},
      ])

      Callbacks.in('a.b').expose('newOne', ary)

      ary.must_equal ['Normal newOne']
    end

    it 'can call a callback in a thread' do
      ary = []

      Thread.new do
        Callbacks.register([
          {"a.b" => ->(name, mutable) { mutable << "Thread #{name}" }},
        ])

        Callbacks.in('a.b').expose('TnewOne', ary)
      end.join

      ary.must_equal ['Thread TnewOne']
    end


    it 'can route callbacks' do
      ary = []
      yra = []

      Callbacks.register([
        {"a.b" => ->(name, mutable) { mutable << "Route1 #{name}" }},
        {"x.y" => ->(name, mutable) { mutable << "Route2 #{name}" }},
      ])

      Callbacks.in('a.b').expose('TnewOne', ary)
      Callbacks.in('x.y').expose('TnewTwo', yra)

      ary.must_equal ['Route1 TnewOne']
      yra.must_equal ['Route2 TnewTwo']
    end

    it 'can be flush' do
      ary = []

      Callbacks.register([
        {"a.b" => ->(name, mutable) { mutable << "Normal #{name}" }},
      ])

      Callbacks.in('a.b').expose('newOne', ary)

      Callbacks.store.size.must_equal 1
      ary.must_equal ['Normal newOne']

      Callbacks.flush_callbacks
      Callbacks.store.size.must_equal 0
    end
  end
end
