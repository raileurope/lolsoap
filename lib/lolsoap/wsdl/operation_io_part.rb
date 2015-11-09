class LolSoap::WSDL
  class OperationIOPart < Element
    def initialize(wsdl, name, type_reference)
      super(wsdl, name, 'soap', type_reference)
    end

    def single_part?
      type.elements.size == 1
    end

    def content
      if single_part?
        type.element(type.elements.keys.first)
      end
    end

    def content_type
      if content
        content.type
      else
        type
      end
    end
  end
end
