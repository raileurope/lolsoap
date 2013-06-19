class LolSoap::WSDL
  class Element
    attr_reader :name, :prefix, :type_reference

    def initialize(wsdl, name, prefix, type_reference, singular = true)
      @wsdl           = wsdl
      @name           = name
      @prefix         = prefix
      @type_reference = type_reference
      @singular       = singular
    end

    def type
      type_reference.type
    end

    def singular?
      @singular == true
    end

    def inspect
      "<#{self.class} name=#{prefix_and_name.inspect} type=#{type.to_s.inspect}>"
    end

    def prefix_and_name
      "#{prefix}:#{name}"
    end

    private

    def wsdl; @wsdl; end
  end
end
