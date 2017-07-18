require 'lolsoap/fault'
require 'lolsoap/hash_builder'
require 'nokogiri'

module LolSoap
  class Response
    attr_reader :request, :doc

    # Create a new instance from a raw XML string
    def self.parse(request, raw)
      new(
        request,
        Nokogiri::XML::Document.parse(
          raw, nil, nil,
          Nokogiri::XML::ParseOptions::DEFAULT_XML &
            Nokogiri::XML::ParseOptions::STRICT
        )
      )
    end

    def initialize(request, doc)
      @request = request
      @doc     = doc
    end

    # Namespace used for SOAP Envelope tags
    def soap_namespace
      request.soap_namespace
    end

    # The XML node for the body of the envelope
    def body
      @body ||= doc.at_xpath('/soap:Envelope/soap:Body/*', 'soap' => soap_namespace)
    end

    # Convert the body node to a Hash, using WSDL type data to determine the structure
    def body_hash(builder = HashBuilder)
      builder.new(body, request.output_type).output
    end

    # The XML node for the header of the envelope
    def header
      @header ||= doc.at_xpath('/soap:Envelope/soap:Header', 'soap' => soap_namespace)
    end

    # SOAP fault, if any
    def fault
      @fault ||= begin
        node = doc.at_xpath('/soap:Envelope/soap:Body/soap:Fault', 'soap' => soap_namespace)
        Fault.new(request, node) if node
      end
    end
  end
end