module LolSoap
  class FaultOx
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
      path = soap_version == '1.2' ? 'soap:Code/soap:Value' : 'faultcode'
      node.locate(path).first.nodes.first
    end

    def reason
      path = soap_version == '1.2' ? 'soap:Reason/soap:Text' : 'faultstring'
      node.locate(path).first.nodes.first
    end

    def detail
      path = soap_version == '1.2' ? 'soap:Detail' : 'detail'
      node.locate(path).first.nodes.map{ |element| Ox.dump(element) }.join
    end
  end
end
