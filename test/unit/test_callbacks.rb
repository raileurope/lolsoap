require 'helper'
require 'lolsoap/callbacks.rb'

module LolSoap
  describe Callbacks do
    before do
      @lol_callbacks = Callbacks.new.tap do |lc|
        lc.for('a.b') << ->(name, mutable) { mutable << "Lol #{name}" }
      end
    end

    after do
      @lol_callbacks.disable
    end

    it 'can store one callback' do
      @lol_callbacks.callbacks.size.must_equal 1
    end

    it 'can call a callback' do
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Lol lol']
    end

    it 'can call a callback in a thread' do
      ary = []
      Thread.new do
        Callbacks.new.tap do |lc|
          lc.for('a.b') << ->(name, mutable) { mutable << "Lol #{name}" }
        end
        Callbacks.in('a.b').expose('lol', ary)
      end.join
      ary.must_equal ['Lol lol']
    end

    it 'can call multiple callbacks' do
      temp = Callbacks.new
      temp.for('a.b') << ->(name, mutable) { mutable << "#{name} more" }
      temp.for('a.b') << ->(name, mutable) { mutable << "#{name} again" }
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Lol lol', 'lol more', 'lol again']
      temp.disable
    end

    it 'can keeep the order on clear' do
      temp = Callbacks.new
      temp.for('a.b') << ->(name, mutable) { mutable << "#{name} more" }
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Lol lol', 'lol more']
      @lol_callbacks.for('a.b').clear
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['lol more']
      @lol_callbacks.for('a.b') << ->(name, mutable) { mutable << "Lol #{name}" }
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Lol lol', 'lol more']
      temp.disable
    end

    it 'can keeep the order on clear in a thread' do
      Thread.new do
        lol_callbacks = Callbacks.new.tap do |lc|
          lc.for('a.b') << ->(name, mutable) { mutable << "Lol #{name}" }
        end

        temp = Callbacks.new
        temp.for('a.b') << ->(name, mutable) { mutable << "#{name} more" }
        ary = []
        Callbacks.in('a.b').expose('lol', ary)
        ary.must_equal ['Lol lol', 'lol more']
        lol_callbacks.for('a.b').clear
        ary = []
        Callbacks.in('a.b').expose('lol', ary)
        ary.must_equal ['lol more']
        lol_callbacks.for('a.b') << ->(name, mutable) { mutable << "Lol #{name}" }
        ary = []
        Callbacks.in('a.b').expose('lol', ary)
        ary.must_equal ['Lol lol', 'lol more']
        lol_callbacks.disable
        temp.disable
      end.join
    end

    it 'can route callbacks' do
      temp = Callbacks.new
      temp.for('c.d') << ->(name, mutable) { mutable << "#{name} c.D" }
      ary = []
      yra = []
      Callbacks.in('c.d').expose('lol', yra)
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Lol lol']
      yra.must_equal ['lol c.D']
      temp.disable
    end

    it 'can be disabled' do
      @lol_callbacks.disable
      temp = Callbacks.new
      temp.for('a.b') << ->(name, mutable) { mutable << "any #{name} ?" }
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['any lol ?']
      temp.disable
    end

    it "can't keep the order on enable" do
      @lol_callbacks.disable
      temp = Callbacks.new
      temp.for('a.b') << ->(name, mutable) { mutable << "any #{name} ?" }
      ary = []
      @lol_callbacks.enable
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['any lol ?', 'Lol lol']
      temp.disable
    end

    it 'can be enabled' do
      @lol_callbacks.disable
      @lol_callbacks.enable
      temp = Callbacks.new
      temp.for('a.b') << ->(name, mutable) { mutable << "any #{name} ?" }
      ary = []
      Callbacks.in('a.b').expose('lol', ary)
      ary.must_equal ['Lol lol', 'any lol ?']
      temp.disable
    end
  end
end
