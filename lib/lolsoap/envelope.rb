require 'nokogiri'
# require 'lolsoap/builder'
require 'lolsoap/builder/hash_params'
require 'lolsoap/builder/block_params'


module LolSoap
  class Envelope
    attr_reader :wsdl, :operation, :doc, :builder

    # @private
    SOAP_1_1 = 'http://schemas.xmlsoap.org/soap/envelope/'

    # @private
    SOAP_1_2 = 'http://www.w3.org/2003/05/soap-envelope'

    def initialize(wsdl, operation, doc = Nokogiri::XML::Document.new)
      @wsdl        = wsdl
      @operation   = operation
      @doc         = doc
      self.builder = :block
      initialize_doc
    end

    def builder=(label)
      @builder = {
        hash:  LolSoap::Builder::HashParams,
        block: LolSoap::Builder::BlockParams
      }.fetch(label)
    end

    # Build the body of the envelope
    #
    # @example
    #   env.body do |b|
    #     b.some 'data'
    #   end
    #
    # @example
    #   env.body(some: 'data')
    #
    def body(*args)
      hash, klass = parse_args(args)
      @builder = klass if klass
      b = builder.new(body_content, input_body_content_type)
      b.parse(hash) if hash
      yield b       if block_given?
      b
    end

    # Build the header of the envelope
    def header(*args)
      hash, klass = parse_args(args)
      @builder = klass if klass
      b = builder.new(header_content, input_header_content_type)
      b.parse(hash) if hash
      yield b       if block_given?
      b
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

    # Namespace used for SOAP envelope tags
    def soap_namespace
      soap_version == '1.2' ? SOAP_1_2 : SOAP_1_1
    end

    # The SOAP version in use
    def soap_version
      wsdl.soap_version
    end

    private

    # @private
    # compatibilty with previous version
    def parse_args(args)
      hash = klass = false
      args.each do |arg|
        if arg.is_a?(Hash)
          hash  = arg
        else
          klass = arg
        end
      end
      [hash, klass]
    end

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
