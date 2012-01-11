class LolSoap::WSDL
  class Type
    attr_reader :name, :namespace

    def initialize(wsdl, name, namespace, elements)
      @wsdl      = wsdl
      @name      = name
      @namespace = namespace
      @elements  = elements
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

    def prefix
      wsdl.prefixes[namespace]
    end

    def inspect
      "<LolSoap::WSDL::Type " \
      "name=#{(prefix + ':' + name).inspect} " \
      "elements=#{elements.inspect}>"
    end

    private

    def wsdl; @wsdl; end
  end
end
