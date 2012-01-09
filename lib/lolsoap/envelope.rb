require 'nokogiri'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

    def initialize(wsdl, operation, builder = Nokogiri::XML::Builder.new)
      @wsdl      = wsdl
      @operation = operation
      @builder   = builder

      initialize_doc
    end

    def namespaces
      namespaces = Hash[wsdl.namespaces.map { |k, v| ["xmlns:#{k}", v] }]
      namespaces['xmlns:soap'] = 'http://schemas.xmlsoap.org/soap/envelope/'
      namespaces
    end

    private

    attr_reader :builder

    def initialize_doc
      builder.Envelope(namespaces) do |env|
        env['soap'].Header do |header|
          @header = header
        end

        env['soap'].Body do |body|
          body[operation.input_prefix].send(operation.input_name) do |input|
            @input = input
          end
        end
      end

      @doc = builder.doc
      @doc.root.namespace = @doc.root.namespace_definitions.find { |d| d.prefix == 'soap' }
    end
  end
end
