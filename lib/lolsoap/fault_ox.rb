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
      Ox.dump(node.locate(path).first.nodes.first)
    end

    # Defined to work similarly to Nokogiri's `at` method
    def at(selector, search_node = node)
      return search_node if search_node.name == selector

      unless search_node.text
        search_node.nodes.each do |child_node|
          result = at(selector, child_node)
          return result if result
        end
      end
      nil
    end
  end
end
