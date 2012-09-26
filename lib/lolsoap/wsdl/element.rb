class LolSoap::WSDL
  class Element
    attr_reader :name

    def initialize(wsdl, name, type_name, singular = true)
      @wsdl      = wsdl
      @name      = name
      @type_name = type_name
      @singular  = singular
    end

    def type
      @type ||= wsdl.type(@type_name)
    end

    def singular?
      @singular == true
    end

    def inspect
      "<#{self.class} name=#{name.inspect} type=#{@type_name.inspect}>"
    end

    private

    def wsdl; @wsdl; end
  end
end
