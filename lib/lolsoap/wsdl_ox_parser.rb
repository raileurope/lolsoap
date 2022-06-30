# frozen_string_literal: true

require 'ox'
require 'cgi'

module LolSoap
  # @private
  class WSDLOxParser < WSDLParser
    class Schema < Struct.new(:target_namespace, :element_form_default, :namespaces)
      UNQUALIFIED = 'unqualified'

      def self.from_node(node)
        new(
          node[:targetNamespace],
          node[:elementFormDefault],
          namespaces(node)
        )
      end

      def self.namespaces(node)
        keys = node.attributes.keys.grep /xmlns/
        node.attributes.slice(*keys)
      end

      def default_form
        element_form_default || UNQUALIFIED
      end
    end

    class Node < WSDLParser::Node
      def initialize(parser, schema, node)
        super(parser, schema, node)

        @namespaces = parser.namespaces.merge(schema.namespaces)
      end
    end

    class Element < WSDLParser::Element
      def initialize(parser, schema, node)
        super(parser, schema, node)

        @form = initialize_form

        @namespace, @name = initialize_namespace_and_name
      end

      def type
        if complex_type = node.locate('xsd:complexType').first
          type = Type.new(parser, schema, complex_type)
          {
            :elements   => type.elements,
            :namespace  => type.namespace,
            :attributes => type.attributes
          }
        elsif type = node[:type]
          parser.namespace_and_name(namespaces, type, target_namespace)
        end
      end

      private

      def initialize_namespace_and_name
        parser.namespace_and_name(namespaces, node[:name].to_s, default_namespace)
      end

      def initialize_form
        node[:form] || schema.default_form
      end

      def max_occurs
        @max_occurs ||= node[:maxOccurs].to_s
      end
    end

    class ReferencedElement < WSDLParser::ReferencedElement; end

    class Type < WSDLParser::Type
      def base_type
        @base_type ||= begin
          if extension = node.locate('*/xsd:extension').first
            parser.type(*parser.namespace_and_name(namespaces, extension[:base]))
          end
        end
      end

      private

      def initialize_namespace_and_name
        parser.namespace_and_name(namespaces, node[:name].to_s, target_namespace)
      end

      def element_nodes
        elements = node.locate('*/xsd:element') +
          node.locate('*/xsd:element') +
          node.locate('xs:complexContent/xs:extension/*/xs:element') +
          node.locate('xs:complexContent/xs:extension/*/*/xs:element')

        elements.uniq.map { |el|
          element = TypeElement.new(parser, schema, el)

          if reference = el[:ref]
            ReferencedElement.new(element, parser.element(*parser.namespace_and_name(namespaces, reference.to_s)))
          else
            element
          end
        }
      end

      def defined_attributes
        (node.locate('xsd:attribute/@name') + node.locate('*/xsd:extension/xsd:attribute/@name')).uniq
      end

      def referenced_attributes
        (node.locate('xsd:attributeGroup[@ref]') + node.locate('*/xsd:extension/xsd:attributeGroup[@ref]'))
          .uniq
          .map { |group| parser.attribute_group(*parser.namespace_and_name(namespaces, group[:ref].to_s)) }
          .flat_map(&:attributes)
      end
    end

    class TypeElement < Element
      def default_namespace
        target_namespace if qualified?
      end
    end

    class AttributeGroup < WSDLParser::AttributeGroup
      def attributes
        own_attributes + referenced_attributes
      end

      def own_attributes
        node.locate('xsd:attribute/@name')
      end

      def referenced_attributes
        node.locate('xsd:attributeGroup[@ref]')
          .uniq
          .map { |group| parser.attribute_group(*parser.namespace_and_name(namespaces, group[:ref].to_s)) }
          .flat_map(&:attributes)
      end
    end

    class Operation < WSDLParser::Operation
      def name
        node[:name].to_s
      end

      def action
        node.locate('soap:operation/@soapAction').first.to_s
      end

      private

      def operation_io(direction)
        OperationIO.new(parser, self, node.locate("wsdl:#{direction}").first)
      end
    end

    class OperationIO < WSDLParser::OperationIO
      def part_elements(name)
        nodes = node.locate("soap:#{name}")
        return [] unless nodes

        nodes.map { |node|
          parts = parser.messages.fetch((node[:message] || operation_message).to_s.split(':').last)

          parts.fetch(node[:parts] || node[:part]) do |part_name|
            if parts.size == 1
              if name == :body
                parts.values.first
              end
            else
              raise ParseError, "Can't determine which part of #{message_name} to use as #{operation.name} #{self.name} #{name}"
            end
          end
        }.compact
      end
    end

    def self.parse(raw)
      new(Ox.parse(raw))
    end

    def namespaces
      definition = doc.locate('wsdl:definitions').first
      keys = definition.attributes.keys.grep /xmlns/

      definition.attributes.slice(*keys)
    end

    def definitions
      doc.locate('wsdl:definitions')
    end

    def endpoint
      @endpoint ||= CGI.unescape(
        doc.locate('wsdl:definitions/wsdl:service/wsdl:port/soap:address/').first.attributes[:location]
      )
    end

    def schemas
      doc.locate('wsdl:definitions/wsdl:types/xsd:schema')
    end

    def types
      @types ||= begin
        types = {}
        each_node('xsd:complexType') do |node, schema|
          type = Type.new(self, schema, node)
          types[type.id] = type_record(type)
        end
        types
      end
    end

    def abstract_types
      @abstract_types ||= begin
        types = {}
        each_node('xsd:complexType[@abstract="true"]') do |node, schema|
          type = Type.new(self, schema, node)
          types[type.id] = type_record(type)
        end
        types
      end
    end

    def type(namespace, name)
      find_node namespace, name, Type, 'complexType'
    end

    def elements
      @elements ||= begin
        elements = {}
        each_node('xsd:element') do |node, schema|
          element = Element.new(self, schema, node)
          elements[element.id] = {
            :name      => element.name,
            :namespace => element.namespace,
            :type      => element.type
          }
        end
        elements
      end
    end

    def element(namespace, name)
      find_node namespace, name, Element, 'element'
    end

    def attribute_group(namespace, name)
      find_node namespace, name, AttributeGroup, 'attributeGroup'
    end

    def messages
      @messages ||= Hash[
        doc.locate('wsdl:definitions/wsdl:message').map { |msg|
          [
            msg[:name].to_s,
            Hash[
              msg.locate('wsdl:part').map { |part|
                [
                  part[:name].to_s,
                  namespace_and_name(namespaces, part[:element])
                ]
              }
            ]
          ]
        }
      ]
    end

    def port_type_operations
      @port_type_operations ||= Hash[
        doc.locate('wsdl:definitions/wsdl:portType/wsdl:operation').map do |op|
          [
            op[:name].to_s,
            {
              "wsdl:input": op.locate('wsdl:input/@message').first.to_s,
              "wsdl:output": op.locate('wsdl:output/@message').first.to_s,
            }
          ]
        end
      ]
    end

    def operations
      @operations ||= begin
        # / vs [@]
        binding = doc.locate('wsdl:definitions/wsdl:service/wsdl:port/@binding').first.to_s.split(':').last

        Hash[
          doc.locate("wsdl:definitions/wsdl:binding[@name=#{binding}]/wsdl:operation").map do |node|
            operation = Operation.new(self, node)

            [
              operation.name,
              {
                :action => operation.action,
                :input  => {
                  :header => operation.input.header,
                  :body   => operation.input.body
                },
                :output => {
                  :header => operation.output.header,
                  :body   => operation.output.body
                }
              }
            ]
          end
        ]
      end
    end

    def soap_version
      @soap_version ||= doc.locate("//soap2:*").present? ? '1.2' : '1.1'
    end

    def namespace_and_name(namespaces, prefixed_name, default_namespace = nil)
      if prefixed_name.include? ':'
        prefix, name = prefixed_name.split(':')
        namespace    = namespaces.fetch("xmlns:#{prefix}".to_sym)
      else
        name      = prefixed_name
        namespace = default_namespace
      end

      [namespace, name]
    end

    def each_node(xpath)
      schemas.each do |schema_node|
        schema = Schema.from_node(schema_node)
        schema_node.locate(xpath).each do |node|
          yield node, schema
        end
      end
    end

    def find_node(namespace, name, node_class, selector)
      node_params = node_params_from_schemas(schemas_matching_namespace(namespace), name, selector)

      node_class.new(self, *node_params) if node_params
    end

    private

    def schemas_matching_namespace(namespace)
      schemas.select { |schema| Schema.from_node(schema).namespaces.values.include?(namespace) }.presence || schemas
    end

    def node_params_from_schemas(schemas, name, selector)
      schemas
        .map { |schema| [Schema.from_node(schema), schema.locate("xsd:#{selector}[@name=#{name.split(':').last}]").first ] }
        .find { |schema, node| node.present? }
    end
  end
end
