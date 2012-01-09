class LolSoap::WSDL
  class NullType
    def prefix
      nil
    end

    def elements
      {}
    end

    def element(name)
      NullType.new
    end
  end
end
