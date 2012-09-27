class LolSoap::WSDL
  class Type
    attr_reader :name, :prefix

    def initialize(name, prefix, elements, attributes)
      @name       = name
      @prefix     = prefix
      @elements   = elements
      @attributes = attributes
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

    def attribute(name)
      @attributes.fetch(name)
    end

    def has_attribute?(name)
      @attributes.include?(name)
    end

    def inspect
      "<#{self.class} name=\"#{prefix}:#{name}\" elements=#{elements.inspect}>"
    end
  end
end
