require 'wasabi'
require 'nokogiri'

module LolSoap
  class WSDL
    require 'lolsoap/wsdl/operation'
    require 'lolsoap/wsdl/type'

    attr_reader :raw

    # @private
    attr_writer :parser

    def initialize(raw)
      @raw = raw
    end

    def operations
      @operations ||= Hash[
        parser.operations.map do |k, op|
          [op[:input], Operation.new(self, op[:action], types[op[:input]])]
        end
      ]
    end

    def types
      @types ||= Hash[
        parser.types.map do |name, type|
          elements  = type.dup
          namespace = elements.delete(:namespace)
          elements  = Hash[elements.map { |k, v| [k, v[:type]] }]

          [name, Type.new(self, name, namespace, elements)]
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

    # We are using Wasabi to parse the WSDL document. This is strictly an
    # implementation detail, and should not be relied upon.
    #
    # @private
    def parser
      @parser ||= begin
        parser = Wasabi::Parser.new Nokogiri::XML(raw)
        parser.parse
        parser
      end
    end
  end
end
