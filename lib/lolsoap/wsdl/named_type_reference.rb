class LolSoap::WSDL
  class NamedTypeReference
    attr_reader :namespace, :name, :wsdl

    def initialize(namespace, name, wsdl)
      @namespace = namespace
      @name      = name
      @wsdl      = wsdl
    end

    def type
      wsdl.type(namespace, name)
    end
  end
end
