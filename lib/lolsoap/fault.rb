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
      node.at_xpath(
        soap_version == '1.2' ? './soap:Code/soap:Value' : './soap:faultcode',
        'soap' => soap_namespace
      ).text.to_s
    end

    def reason
      node.at_xpath(
        soap_version == '1.2' ? './soap:Reason/soap:Text' : './soap:faultstring',
        'soap' => soap_namespace
      ).text.to_s
    end

    def detail
      node.at_xpath(
        soap_version == '1.2' ? './soap:Detail/*' : './soap:detail/*',
        'soap' => soap_namespace
      ).to_xml
    end
  end
end
