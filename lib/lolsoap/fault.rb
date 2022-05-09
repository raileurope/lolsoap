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

    def soap_version
      request.soap_version
    end

    def code
      selector = soap_version == '1.2' ? './soap:Code/soap:Value' : './faultcode'
      query_result = node.at_xpath(selector, 'soap' => soap_namespace) ||
                     node.at_xpath('./Code/Value', 'soap' => soap_namespace)
      element = query_result.element? ? query_result : query_result.element
      element.text.to_s
    end

    def reason
      selector = soap_version == '1.2' ? './soap:Reason/soap:Text' : './faultstring'
      query_result = node.at_xpath(selector, 'soap' => soap_namespace) ||
                     node.at_xpath('./Reason/Text', 'soap' => soap_namespace)
      element = query_result.element? ? query_result : query_result.element
      element.text.to_s
    end

    def detail
      selector = soap_version == '1.2' ? './soap:Detail/*' : './detail/*'
      query_result = node.at_xpath(selector, 'soap' => soap_namespace) ||
                     node.at_xpath('./Detail/*', 'soap' => soap_namespace)
      element = query_result.element? ? query_result : query_result.element
      element.to_xml
    end

    def at(selector)
      node.at(selector)
    end
  end
end
