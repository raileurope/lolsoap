require 'set'

class LolSoap::WSDL
  class Type
    attr_reader :name, :prefix

    def initialize(name, prefix, elements, attributes)
      @name       = name
      @prefix     = prefix
      @elements   = elements
      @attributes = Set.new(attributes)
    end

    def elements
      @elements.dup
    end

    def element(name)
      @elements.fetch(name) { NullElement.new }
    end

    def element_prefix(name)
      @elements.fetch(name, self).prefix
    end

    def sub_type(name)
      element(name).type
    end

    def attributes
      @attributes.to_a
    end

    def has_attribute?(name)
      @attributes.include?(name)
    end

    def inspect
      "<#{self.class} name=\"#{prefix_and_name.inspect}\" " \
        "elements=#{elements.inspect} " \
        "attributes=#{attributes.inspect}>"
    end

    def prefix_and_name
      "#{prefix}:#{name}"
    end
  end
end
