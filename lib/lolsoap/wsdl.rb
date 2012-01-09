require 'lolsoap/wsdl_parser'

module LolSoap
  class WSDL
    require 'lolsoap/wsdl/operation'
    require 'lolsoap/wsdl/type'
    require 'lolsoap/wsdl/null_type'

    def self.parse(raw)
      new(WSDLParser.parse(raw))
    end

    attr_reader :parser

    def initialize(parser)
      @parser = parser
    end

    def operations
      @operations ||= Hash[
        parser.operations.map do |k, op|
          [k, Operation.new(self, op[:action], types[op[:input][:name]])]
        end
      ]
    end

    def types
      @types ||= Hash[
        parser.types.map do |name, type|
          [name, Type.new(self, name, type[:namespace], type[:elements])]
        end
      ]
    end

    def endpoint
      parser.endpoint
    end

    def namespaces
      parser.namespaces
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
  end
end
