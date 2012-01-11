require 'lolsoap/errors'
require 'lolsoap/fault'
require 'lolsoap/hash_builder'
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

      raise FaultRaised.new(fault) if fault
    end

    def soap_namespace
      request.soap_namespace
    end

    def body
      @body ||= doc.at_xpath('/soap:Envelope/soap:Body/*', 'soap' => soap_namespace)
    end

    def body_hash(builder = HashBuilder)
      builder.new(body, request.output_type).output
    end

    def header
      @header ||= doc.at_xpath('/soap:Envelope/soap:Header', 'soap' => soap_namespace)
    end

    def fault
      @fault ||= begin
        node = doc.at_xpath('/soap:Envelope/soap:Body/soap:Fault', 'soap' => soap_namespace)
        Fault.new(request, node) if node
      end
    end
  end
end
