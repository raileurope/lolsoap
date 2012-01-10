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

    def ==(other)
      self.class === other
    end
  end
end
