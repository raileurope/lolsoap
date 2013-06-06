class LolSoap::WSDL
  class Element
    attr_reader :name

    def initialize(wsdl, name, type, singular = true)
      @wsdl      = wsdl
      @name      = name
      @type      = type
      @singular  = singular
    end

    def type
      if @type.is_a?(String)
        @type = wsdl.type(@type)
      end

      @type
    end

    def singular?
      @singular == true
    end

    def inspect
      "<#{self.class} name=#{name.inspect} type=#{type.to_s.inspect}>"
    end

    private

    def wsdl; @wsdl; end
  end
end
