require 'nokogiri'
require 'lolsoap/builder'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

    # @private
    SOAP_1_1 = 'http://schemas.xmlsoap.org/soap/envelope/'

    # @private
    SOAP_1_2 = 'http://www.w3.org/2003/05/soap-envelope'

    def initialize(wsdl, operation, doc = Nokogiri::XML::Document.new)
      @wsdl      = wsdl
      @operation = operation
      @doc       = doc

      initialize_doc
    end

    # Build the body of the envelope
    #
    # @example
    #   env.body do |b|
    #     b.some 'data'
    #   end
    def body(klass = Builder)
      builder = klass.new(content, input_type)
      yield builder if block_given?
      builder
    end

    # Build the header of the envelope
    def header(klass = Builder)
      builder = klass.new(@header)
      yield builder if block_given?
      builder
    end

    def endpoint
      wsdl.endpoint
    end

    def action
      operation.action
    end

    def input
      operation.input
    end

    def input_type
      input.type
    end

    def output
      operation.output
    end

    def output_type
      output.type
    end

    def to_xml(options = {})
      doc.to_xml(options)
    end

    def soap_prefix
      'soap'
    end

    def soap_namespace
      soap_version == '1.2' ? SOAP_1_2 : SOAP_1_1
    end

    def soap_version
      wsdl.soap_version
    end

    private

    # @private
    def content; @content; end

    # @private
    def initialize_doc
      doc.root = root = doc.create_element('Envelope')

      namespaces = Hash[wsdl.type_namespaces.map { |prefix, uri| [prefix, root.add_namespace(prefix, uri)] }]
      namespaces[soap_prefix] = root.add_namespace(soap_prefix, soap_namespace)

      @header = doc.create_element 'Header'

      @body    = doc.create_element 'Body'
      @content = doc.create_element input.name

      [root, @header, @body].each { |el| el.namespace = namespaces[soap_prefix] }
      @content.namespace = namespaces[input.prefix]

      @body << @content
      root  << @header
      root  << @body
    end
  end
end
