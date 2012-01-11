require 'nokogiri'
require 'lolsoap/builder'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

    # @private
    SOAP_PREFIX    = 'soap'

    # @private
    SOAP_NAMESPACE = 'http://www.w3.org/2003/05/soap-envelope'

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
      builder = klass.new(input, operation.input)
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

    def input_type
      operation.input
    end

    def output_type
      operation.output
    end

    def to_xml
      doc.to_xml
    end

    def soap_prefix
      SOAP_PREFIX
    end

    def soap_namespace
      SOAP_NAMESPACE
    end

    private

    # @private
    def input; @input; end

    # @private
    def initialize_doc
      doc.root = root = doc.create_element('Envelope')

      namespaces = Hash[wsdl.type_namespaces.map { |prefix, uri| [prefix, root.add_namespace(prefix, uri)] }]
      namespaces[soap_prefix] = root.add_namespace(soap_prefix, soap_namespace)

      @header = doc.create_element 'Header'

      @body  = doc.create_element 'Body'
      @input = doc.create_element input_type.name

      [root, @header, @body].each { |el| el.namespace = namespaces[soap_prefix] }
      @input.namespace = namespaces[input_type.prefix]

      @body << @input
      root  << @header
      root  << @body
    end
  end
end
