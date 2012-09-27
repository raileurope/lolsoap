class LolSoap::WSDL
  class Element < TypeComponent
    def initialize(wsdl, name, type_name, singular = true)
      super(wsdl, name, type_name)
      @singular = singular
    end

    def singular?
      @singular == true
    end
  end
end
