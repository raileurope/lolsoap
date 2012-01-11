module LolSoap
  class Fault
    attr_reader :request, :node

    def initialize(request, node)
      @request = request
      @node    = node
    end

    def soap_namespace
      request.soap_namespace
    end

    def code
      node.at_xpath('./soap:Code/soap:Value', 'soap' => soap_namespace).text.to_s
    end

    def reason
      node.at_xpath('./soap:Reason/soap:Text', 'soap' => soap_namespace).text.to_s
    end

    def detail
      node.at_xpath('./soap:Detail/*', 'soap' => soap_namespace).to_xml
    end
  end
end
