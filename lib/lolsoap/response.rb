require 'lolsoap/fault'
require 'lolsoap/fault_ox'
require 'lolsoap/hash_builder'
require 'lolsoap/hash_builder_ox'
require 'ox'

module LolSoap
  class Response
    USE_OX = true # "dual booting"
    attr_reader :request, :doc, :raw

    def self.old_parse(request, raw)
      new(
        request,
        Nokogiri::XML::Document.parse(
          raw, nil, nil,
          Nokogiri::XML::ParseOptions::DEFAULT_XML &
            Nokogiri::XML::ParseOptions::STRICT
        )
      )
    end

    # Create a new instance from a raw XML string
    def self.parse(request, raw)
      USE_OX ? ox_parse(request, raw) : old_parse(request, raw)
    end

    def self.ox_parse(request, raw)
      new(
        request,
        Ox.load(raw, { mode: :generic, effort: :strict }),
        raw
      )
    end

    def initialize(request, doc, raw = nil)
      @request = request
      @doc     = doc
      @raw = raw # Only needed in Ox mode
    end

    # Namespace used for SOAP Envelope tags
    def soap_namespace
      request.soap_namespace
    end

    def ox_body
      # doc.nodes.first.locate('/soap:Envelope/soap:Body')
      doc.locate('soap:Envelope/soap:Body').first.nodes.first
    end

    # The XML node for the body of the envelope
    def body
      # require 'pry'; binding.pry
      # puts doc.at_xpath('/soap:Envelope/soap:Body/*', 'soap' => soap_namespace)
      @body ||= USE_OX ? ox_body : doc.at_xpath('/soap:Envelope/soap:Body/*', 'soap' => soap_namespace)
    end

    # Convert the body node to a Hash, using WSDL type data to determine the structure
    def body_hash(builder = HashBuilder)
      USE_OX ? ox_body_hash : builder.new(body, request.output_type).output
    end

    def ox_body_hash
      HashBuilderOx.new(raw).output
      # Ox.load(raw, mode: :hash)
    end

    # The XML node for the header of the envelope
    def header
      USE_OX ? ox_header : doc.at_xpath('/soap:Envelope/soap:Header', 'soap' => soap_namespace)
    end

    def ox_header
      doc.locate('soap:Envelope/soap:Header').first&.nodes&.first
    end

    # SOAP fault, if any
    def fault
      @fault ||= begin
        return ox_fault if USE_OX

        node = doc.at_xpath('/soap:Envelope/soap:Body/soap:Fault', 'soap' => soap_namespace)
        Fault.new(request, node) if node
      end
    end

    def ox_fault
      node = doc.locate('soap:Envelope/soap:Body/soap:Fault').first
      FaultOx.new(request, node) if node
    end
  end
end
