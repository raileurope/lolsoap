require 'nokogiri'

module LolSoap
  class Response
    attr_reader :request, :doc

    def self.parse(request, raw)
      new(request, Nokogiri::XML::Document.parse(raw))
    end

    def initialize(request, doc)
      @request = request
      @doc     = doc
    end

    def soap_namespace
      request.soap_namespace
    end

    def body
      doc.at_xpath('/soap:Envelope/soap:Body/*', 'soap' => soap_namespace)
    end

    def header
      doc.at_xpath('/soap:Envelope/soap:Header', 'soap' => soap_namespace)
    end
  end
end
