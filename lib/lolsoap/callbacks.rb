class LolSoap::Callbacks
  @registered = []

  class Selected
    def initialize(callbacks = [])
      @callbacks = callbacks
    end

    def expose(*args)
      @callbacks.each { |c| c.call(*args) }
    end
  end

  class << self
    def in(key)
      Selected.new(*@registered.map { |c| c.procs[key] })
    end

    def register(*klass)
      @registered |= klass
    end

    def unregister(klass)
      @registered.delete(klass)
    end
  end

  def initialize
    enable
    @procs = {}
  end

  attr_accessor :procs

  def for(key)
    procs[key] ||= []
  end

  def enable
    self.class.register(self)
  end

  def disable
    self.class.unregister(self)
  end
end
