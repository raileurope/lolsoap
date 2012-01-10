require 'nokogiri'
require 'lolsoap/builder'

module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc

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

    private

    attr_reader :input

    def initialize_doc
      doc.root = root = doc.create_element 'Envelope'

      namespaces = Hash[wsdl.namespaces.map { |prefix, uri| [prefix, root.add_namespace(prefix, uri)] }]
      namespaces['soap'] = root.add_namespace('soap', 'http://schemas.xmlsoap.org/soap/envelope/')

      @header = doc.create_element 'Header'

      @body  = doc.create_element 'Body'
      @input = doc.create_element operation.input_name

      [root, @header, @body].each { |el| el.namespace = namespaces['soap'] }
      @input.namespace = namespaces[operation.input_prefix]

      @body << @input
      root  << @header
      root  << @body
    end
  end
end
