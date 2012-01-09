require 'nokogiri'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

    def initialize(wsdl, operation)
      @wsdl      = wsdl
      @operation = operation

      initialize_doc
    end

    def namespaces
      namespaces = Hash[wsdl.namespaces.map { |k, v| ["xmlns:#{k}", v] }]
      namespaces['xmlns:soap'] = 'http://schemas.xmlsoap.org/soap/envelope/'
      namespaces
    end

    private

    def initialize_doc
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Envelope(namespaces) do |env|
          env['soap'].Header
          env['soap'].Body do |body|
            body[operation.input_prefix].send(operation.input_name)
          end
        end
      end

      @doc = builder.doc
      @doc.root.namespace = @doc.root.namespace_definitions.find { |d| d.prefix == 'soap' }
    end
  end
end
