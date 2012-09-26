class LolSoap::WSDL
  class Type
    attr_reader :name, :prefix

    def initialize(name, prefix, elements)
      @name     = name
      @prefix   = prefix
      @elements = elements
    end

    def elements
      @elements.dup
    end

    def element(name)
      @elements.fetch(name) { NullElement.new }
    end

    def sub_type(name)
      element(name).type
    end

    def inspect
      "<#{self.class} name=\"#{prefix}:#{name}\" elements=#{elements.inspect}>"
    end
  end
end
