class LolSoap::WSDL
  class Type
    attr_reader :wsdl, :name, :namespace

    def initialize(wsdl, name, namespace, elements)
      @wsdl          = wsdl
      @name          = name
      @namespace     = namespace
      @element_types = elements
    end

    def elements
      load_elements.dup
    end

    def element(name)
      load_elements.fetch(name) { NullType.new }
    end

    def prefix
      wsdl.prefixes[namespace]
    end

    def inspect
      "<LolSoap::WSDL::Type " \
      "name=#{name.inspect} " \
      "namespace=#{namespace.inspect}>"
    end

    private

    def load_elements
      @elements ||= Hash[@element_types.map { |name, type| [name, wsdl.types[type.split(':').last]] }]
    end
  end
end
