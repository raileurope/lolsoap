require 'lolsoap/wsdl_parser'

module LolSoap
  class WSDL
    require 'lolsoap/wsdl/operation'
    require 'lolsoap/wsdl/operation_io'
    require 'lolsoap/wsdl/type'
    require 'lolsoap/wsdl/named_type_reference'
    require 'lolsoap/wsdl/immediate_type_reference'
    require 'lolsoap/wsdl/null_type'
    require 'lolsoap/wsdl/element'
    require 'lolsoap/wsdl/null_element'

    # Create a new instance by parsing a raw string of XML
    def self.parse(raw)
      new(WSDLParser.parse(raw))
    end

    # The SOAP endpoint URL
    attr_reader :endpoint

    # Hash of generated prefixes to namespaces
    attr_reader :prefixes

    # Hash of namespaces to generated prefixes
    attr_reader :namespaces

    # The version of SOAP detected.
    attr_reader :soap_version

    def initialize(parser)
      @prefixes     = generate_prefixes(parser)
      @namespaces   = prefixes.invert
      @types        = load_types(parser)
      @operations   = load_operations(parser)
      @endpoint     = parser.endpoint
      @soap_version = parser.soap_version
    end

    # Hash of types declared by the service
    def types
      Hash[@types.values.map { |t| [t.name, t] }]
    end

    # Get a single type, or a NullType if the type doesn't exist
    def type(namespace, name)
      @types.fetch([namespace, name]) { NullType.new }
    end

    # Hash of operations that are supported by the SOAP service
    def operations
      Hash[@operations.values.map { |o| [o.name, o] }]
    end

    # Get a single operation
    def operation(name)
      @operations.fetch(name)
    end

    # Get the prefix for a namespace
    def prefix(namespace)
      prefixes.fetch namespace
    end

    def inspect
      "<#{self.class} " \
      "namespaces=#{namespaces.inspect} " \
      "operations=#{operations.inspect} " \
      "types=#{types.inspect}>"
    end

    private

    # @private
    def load_types(parser)
      Hash[
        parser.types.map do |id, type|
          [id, build_type(type)]
        end
      ]
    end

    # @private
    def load_operations(parser)
      Hash[
        parser.operations.map do |k, op|
          [k, Operation.new(
            self,
            k,
            op[:action],
            build_io(op[:input], parser),
            build_io(op[:output], parser)
          )]
        end
      ]
    end

    # @private
    def generate_prefixes(parser)
      prefixes = {}
      index    = 0

      parser.types.merge(parser.elements).values.each do |el|
        unless prefixes[el[:namespace]]
          prefixes[el[:namespace]] = "ns#{index}"
          index += 1
        end
      end

      prefixes
    end

    # @private
    def build_type(params)
      Type.new(
        params[:name],
        prefix(params.fetch(:namespace)),
        build_elements(params.fetch(:elements)),
        params.fetch(:attributes)
      )
    end

    # @private
    def build_elements(elements)
      Hash[
        elements.map do |name, el|
          [name, build_element(el)]
        end
      ]
    end

    # @private
    def build_element(params)
      Element.new(
        self,
        params[:name],
        prefix(params[:namespace]),
        type_reference(params[:type]),
        params[:singular]
      )
    end

    # @private
    def type_reference(type)
      if type.is_a?(Array)
        NamedTypeReference.new(*type, self)
      else
        ImmediateTypeReference.new(type ? build_type(type) : NullType.new)
      end
    end

    # @private
    def build_io(io, parser)
      OperationIO.new(
        io[:header] && build_element(parser.elements[io[:header]]),
        build_element(parser.elements[io[:body]])
      )
    end
  end
end
