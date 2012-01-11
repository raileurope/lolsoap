require 'nokogiri'
require 'lolsoap/builder'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

    SOAP_PREFIX    = 'soap'
    SOAP_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/'

    def initialize(wsdl, operation, doc = Nokogiri::XML::Document.new)
      @wsdl      = wsdl
      @operation = operation
      @doc       = doc

      initialize_doc
    end

    def body(klass = Builder)
      builder = klass.new(input, operation.input)
      yield builder if block_given?
      builder
    end

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

    attr_reader :input

    def initialize_doc
      doc.root = root = doc.create_element 'Envelope'

      namespaces = Hash[wsdl.type_namespaces.map { |prefix, uri| [prefix, root.add_namespace(prefix, uri)] }]
      namespaces[soap_prefix] = root.add_namespace(soap_prefix, soap_namespace)

      @header = doc.create_element 'Header'

      @body  = doc.create_element 'Body'
      @input = doc.create_element operation.input_name

      [root, @header, @body].each { |el| el.namespace = namespaces[soap_prefix] }
      @input.namespace = namespaces[operation.input_prefix]

      @body << @input
      root  << @header
      root  << @body
    end
  end
end
