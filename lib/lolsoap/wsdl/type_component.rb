class LolSoap::WSDL
  # TypeComponent is an abstract superclass of Attribute and Element
  class TypeComponent
    attr_reader :name

    def initialize(wsdl, name, type_name)
      @wsdl      = wsdl
      @name      = name
      @type_name = type_name
    end

    def type
      @type ||= wsdl.type(@type_name)
    end

    def inspect
      "<#{self.class} name=#{name.inspect} type=#{@type_name.inspect}>"
    end

    private

    def wsdl; @wsdl; end
  end
end
