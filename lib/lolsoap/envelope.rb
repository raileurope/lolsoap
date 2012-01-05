require 'nokogiri'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

    def initialize(wsdl, operation)
      @wsdl      = wsdl
      @operation = operation

      initialize_doc
    end

    private

    def namespaces
      { 'xmlns:soap' =>'http://schemas.xmlsoap.org/soap/envelope/' }
    end

    def initialize_doc
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Envelope(namespaces) do |env|
          env['soap'].Header
          env['soap'].Body
        end
      end

      @doc = builder.doc
      @doc.root.namespace = @doc.root.namespace_definitions.first
    end
  end
end
