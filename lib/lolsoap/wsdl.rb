require 'lolsoap/wsdl_parser'

module LolSoap
  class WSDL
    require 'lolsoap/wsdl/operation'
    require 'lolsoap/wsdl/type'
    require 'lolsoap/wsdl/null_type'
    require 'lolsoap/wsdl/element'
    require 'lolsoap/wsdl/null_element'

    # Create a new instance by parsing a raw string of XML
    def self.parse(raw)
      new(WSDLParser.parse(raw))
    end

    attr_reader :parser

    def initialize(parser)
      @parser = parser
    end

    # Hash of operations that are supports by the SOAP service
    def operations
      load_operations.dup
    end

    # Get a single operation
    def operation(name)
      load_operations.fetch(name)
    end

    # Hash of types declared by the service
    def types
      load_types.dup
    end

    # Get a single type, or a NullType if the type doesn't exist
    def type(name)
      load_types.fetch(name) { NullType.new }
    end

    # The SOAP endpoint URL
    def endpoint
      parser.endpoint
    end

    # Hash of namespaces used in the WSDL document (keys are prefixes)
    def namespaces
      parser.namespaces
    end

    # Hash of namespace prefixes used in the WSDL document (keys are namespace URIs)
    def prefixes
      parser.prefixes
    end

    # Namespaces used by the types (a subset of #namespaces)
    def type_namespaces
      Hash[load_types.values.map { |type| [type.prefix, namespaces[type.prefix]] }]
    end

    # The version of SOAP detected.
    def soap_version
      parser.soap_version
    end

    def inspect
      "<#{self.class} " \
      "namespaces=#{namespaces.inspect} " \
      "operations=#{operations.keys.inspect} " \
      "types=#{types.keys.inspect}>"
    end

    private

    # @private
    def load_operations
      @operations ||= Hash[
        parser.operations.map do |k, op|
          [k, Operation.new(self, op[:action], type(op[:input]), type(op[:output]))]
        end
      ]
    end

    # @private
    def load_types
      @types ||= Hash[
        parser.types.map do |prefixed_name, type|
          [prefixed_name, Type.new(type[:name], type[:prefix], build_elements(type[:elements]))]
        end
      ]
    end

    # @private
    def build_elements(elements)
      Hash[
        elements.map do |name, el|
          [name, Element.new(self, name, el[:type], el[:singular])]
        end
      ]
    end
  end
end
