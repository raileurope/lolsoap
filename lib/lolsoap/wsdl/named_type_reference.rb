class LolSoap::WSDL
  class NamedTypeReference
    attr_reader :name, :wsdl

    def initialize(name, wsdl)
      @name = name
      @wsdl = wsdl
    end

    def type
      wsdl.type(name)
    end
  end
end
