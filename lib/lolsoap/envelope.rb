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
      builder = klass.new(body_content, input_body_content_type)
      yield builder if block_given?
      builder
    end

    # Build the header of the envelope
    def header(klass = Builder)
      builder = klass.new(header_content, input_header_content_type)
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

    def input_header
      input.header
    end

    def input_header_content
      input_header.content
    end

    def input_header_content_type
      input_header.content_type
    end

    def input_body
      input.body
    end

    def input_body_content
      input_body.content
    end

    def input_body_content_type
      input_body.content_type
    end

    def output
      operation.output
    end

    def output_header
      output.header
    end

    def output_header_type
      output_header && output_header.type
    end

    def output_body
      output.body
    end

    def output_body_content
      output_body.content
    end

    def output_body_content_type
      output_body.content_type
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
    def header_content; @header_content; end

    # @private
    def body_content; @body_content; end

    # @private
    def initialize_doc
      doc.root = root = doc.create_element('Envelope')

      namespaces = Hash[wsdl.namespaces.map { |prefix, uri| [prefix, root.add_namespace(prefix, uri)] }]
      namespaces[soap_prefix] = root.add_namespace(soap_prefix, soap_namespace)

      @header = doc.create_element input_header.name
      @body   = doc.create_element input_body.name

      [root, @header, @body].each { |el| el.namespace = namespaces[soap_prefix] }

      if input_header_content
        @header_content = doc.create_element input_header_content.name
        @header_content.namespace = namespaces[input_header_content.prefix]
        @header << @header_content
      else
        @header_content = @header
      end

      if input_body_content
        @body_content = doc.create_element input_body_content.name
        @body_content.namespace = namespaces[input_body_content.prefix]
        @body << @body_content
      else
        @body_content = @body
      end

      root << @header
      root << @body
    end
  end
end
