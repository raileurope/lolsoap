require 'lolsoap/wsdl_parser'

module LolSoap
  class WSDL
    require 'lolsoap/wsdl/operation'
    require 'lolsoap/wsdl/type'
    require 'lolsoap/wsdl/null_type'
    require 'lolsoap/wsdl/element'
    require 'lolsoap/wsdl/null_element'

    def self.parse(raw)
      new(WSDLParser.parse(raw))
    end

    attr_reader :parser

    def initialize(parser)
      @parser = parser
    end

    def operations
      load_operations.dup
    end

    def operation(name)
      load_operations[name]
    end

    def types
      load_types.dup
    end

    def type(name)
      load_types.fetch(name) { NullType.new }
    end

    def endpoint
      parser.endpoint
    end

    def namespaces
      parser.namespaces
    end

    def type_namespaces
      Hash[parser.types.map { |k, t| [prefixes[t[:namespace]], t[:namespace]] }]
    end

    def prefixes
      namespaces.invert
    end

    def inspect
      "<LolSoap::WSDL " \
      "namespaces=#{namespaces.inspect} " \
      "operations=#{operations.inspect} " \
      "types=#{types.inspect}>"
    end

    private

    def load_operations
      @operations ||= Hash[
        parser.operations.map do |k, op|
          [k, Operation.new(self, op[:action], type(op[:input][:name]), type(op[:output][:name]))]
        end
      ]
    end

    def load_types
      @types ||= Hash[
        parser.types.map do |name, type|
          [name, Type.new(self, name, type[:namespace], build_elements(type[:elements]))]
        end
      ]
    end

    def build_elements(elements)
      Hash[
        elements.map do |name, el|
          [name, Element.new(self, name, el[:type], el[:singular])]
        end
      ]
    end
  end
end
