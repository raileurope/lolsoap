require 'nokogiri'
require 'cgi'

module LolSoap
  # @private
  class WSDLParser
    class ParseError < StandardError; end

    class Schema < Struct.new(:target_namespace, :element_form_default)
      UNQUALIFIED = 'unqualified'

      def self.from_node(node)
        new(
          node.attr('targetNamespace').to_s,
          node.attr('elementFormDefault')
        )
      end

      def default_form
        element_form_default || UNQUALIFIED
      end
    end

    class Node
      attr_reader :parser, :node, :schema, :name, :namespace

      def initialize(parser, schema, node)
        @parser = parser
        @node   = node
        @schema = schema
      end

      def id
        [namespace, name]
      end

      def target_namespace
        schema.target_namespace
      end
    end

    class Element < Node
      QUALIFIED = 'qualified'

      attr_reader :form

      def initialize(*params)
        super(*params)

        @form = node.attr('form') || schema.default_form

        @namespace, @name = parser.namespace_and_name(node, node.attr('name').to_s, default_namespace)
      end

      def type
        if complex_type = node.at_xpath('xs:complexType', parser.ns)
          type = Type.new(parser, schema, complex_type)
          {
            :elements   => type.elements,
            :namespace  => type.namespace,
            :attributes => type.attributes
          }
        elsif type = node.attr('type')
          parser.namespace_and_name(node, type, target_namespace)
        end
      end

      def singular
        max_occurs.empty? || max_occurs == '1'
      end

      def qualified?
        form == QUALIFIED
      end

      def default_namespace
        target_namespace
      end

      private

      def max_occurs
        @max_occurs ||= node.attribute('maxOccurs').to_s
      end
    end

    class ReferencedElement
      attr_reader :reference, :element

      def initialize(reference, element)
        @reference = reference
        @element   = element
      end

      def name
        element.name
      end

      def namespace
        element.namespace
      end

      def type
        element.type
      end

      def singular
        reference.singular
      end
    end

    class Type < Node
      def initialize(*params)
        super(*params)

        @namespace, @name = parser.namespace_and_name(node, node.attr('name').to_s, target_namespace)
      end

      def elements
        parent_elements.merge(own_elements)
      end

      def attributes
        parent_attributes + own_attributes
      end

      def base_type
        @base_type ||= begin
          if extension = node.at_xpath('*/xs:extension', parser.ns)
            parser.type(*parser.namespace_and_name(extension, extension.attribute('base').to_s))
          end
        end
      end

      private

      def own_elements
        Hash[
          element_nodes.map do |element|
            [
              element.name,
              {
                :name      => element.name,
                :namespace => element.namespace,
                :type      => element.type,
                :singular  => element.singular
              }
            ]
          end
        ]
      end

      def element_nodes
        node.xpath('*/xs:element | */*/xs:element | xs:complexContent/xs:extension/*/xs:element | xs:complexContent/xs:extension/*/*/xs:element', parser.ns).map { |el|
          element = TypeElement.new(parser, schema, el)

          if reference = el.attribute('ref')
            ReferencedElement.new(element, parser.element(*parser.namespace_and_name(el, reference.to_s)))
          else
            element
          end
        }
      end

      def parent_elements
        base_type ? base_type.elements : {}
      end

      def own_attributes
        defined_attributes + referenced_attributes
      end

      def defined_attributes
        node.xpath('xs:attribute/@name | */xs:extension/xs:attribute/@name', parser.ns).map(&:text)
      end

      def referenced_attributes
        node.xpath('xs:attributeGroup[@ref] | */xs:extension/xs:attributeGroup[@ref]', parser.ns).map { |group|
          parser.attribute_group(*parser.namespace_and_name(group, group.attribute('ref').to_s))
        }.flat_map(&:attributes)
      end

      def parent_attributes
        base_type ? base_type.attributes : []
      end
    end

    class TypeElement < Element
      def default_namespace
        target_namespace if qualified?
      end
    end

    class AttributeGroup < Node
      def attributes
        own_attributes + referenced_attributes
      end

      def own_attributes
        node.xpath('xs:attribute/@name', parser.ns).map(&:text)
      end

      def referenced_attributes
        node.xpath('xs:attributeGroup[@ref]', parser.ns).map { |group|
          parser.attribute_group(*parser.namespace_and_name(group, group.attribute('ref').to_s))
        }.flat_map(&:attributes)
      end
    end

    class Operation
      attr_reader :parser, :node

      def initialize(parser, node)
        @parser = parser
        @node   = node
      end

      def name
        node.attribute('name').to_s
      end

      def action
        node.at_xpath('./s:operation/@soapAction', parser.ns).to_s
      end

      def input
        @input ||= operation_io(:input)
      end

      def output
        @output ||= operation_io(:output)
      end

      def port_type_operation
        parser.port_type_operations.fetch(name)
      end

      private

      def operation_io(direction)
        OperationIO.new(parser, self, node.at_xpath("d:#{direction}", parser.ns))
      end
    end

    class OperationIO < Struct.new(:parser, :operation, :node)
      def name
        node.name
      end

      def header
        @header ||= part_elements(:header)
      end

      def body
        @body ||= part_elements(:body)
      end

      private

      def operation_message
        operation.port_type_operation[name.to_sym]
      end

      def part_elements(name)
        nodes = node.xpath("s:#{name}", parser.ns)
        return [] unless nodes

        nodes.map { |node|
          parts = parser.messages.fetch((node['message'] || operation_message).to_s.split(':').last)

          parts.fetch(node['parts'] || node['part']) do |part_name|
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

    SOAP_1_1 = 'http://schemas.xmlsoap.org/wsdl/soap/'
    SOAP_1_2 = 'http://schemas.xmlsoap.org/wsdl/soap12/'

    attr_reader :doc

    def self.parse(raw)
      new(Nokogiri::XML::Document.parse(raw))
    end

    def initialize(doc)
      @doc = doc
    end

    def endpoint
      @endpoint ||= CGI.unescape(doc.at_xpath('/d:definitions/d:service/d:port/s:address/@location', ns).to_s)
    end

    def schemas
      doc.xpath('/d:definitions/d:types/xs:schema', ns)
    end

    def types
      @types ||= begin
        types = {}
        each_node('xs:complexType[not(@abstract="true")]') do |node, schema|
          type = Type.new(self, schema, node)
          types[type.id] = {
            :name       => type.name,
            :namespace  => type.namespace,
            :elements   => type.elements,
            :attributes => type.attributes
          }
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
        each_node('xs:element') do |node, schema|
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
        doc.xpath('/d:definitions/d:message', ns).map { |msg|
          [
            msg.attribute('name').to_s,
            Hash[
              msg.xpath('d:part', ns).map { |part|
                [
                  part.attribute('name').to_s,
                  namespace_and_name(part, part['element'])
                ]
              }
            ]
          ]
        }
      ]
    end

    def port_type_operations
      @port_type_operations ||= Hash[
        doc.xpath('/d:definitions/d:portType/d:operation', ns).map do |op|
          [
            op.attribute('name').to_s,
            {
              :input  => op.at_xpath('./d:input/@message',  ns).to_s,
              :output => op.at_xpath('./d:output/@message', ns).to_s
            }
          ]
        end
      ]
    end

    def operations
      @operations ||= begin
        binding = doc.at_xpath('/d:definitions/d:service/d:port/s:address/../@binding', ns).to_s.split(':').last

        Hash[
          doc.xpath("/d:definitions/d:binding[@name='#{binding}']/d:operation", ns).map do |node|
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
      @soap_version ||= doc.at_xpath("//s2:*", "s2" => SOAP_1_2) ? '1.2' : '1.1'
    end

    def ns
      @ns ||= {
        'd'  => 'http://schemas.xmlsoap.org/wsdl/',
        'xs' => 'http://www.w3.org/2001/XMLSchema',
        's'  => soap_version == '1.2' ? SOAP_1_2 : SOAP_1_1
      }
    end

    def namespace_and_name(node, prefixed_name, default_namespace = nil)
      if prefixed_name.include? ':'
        prefix, name = prefixed_name.split(':')
        namespace    = node.namespaces.fetch("xmlns:#{prefix}")
      else
        name      = prefixed_name
        namespace = default_namespace
      end

      [namespace, name]
    end

    def each_node(xpath)
      schemas.each do |schema_node|
        schema = Schema.from_node(schema_node)
        schema_node.xpath(xpath, ns).each do |node|
          yield node, schema
        end
      end
    end

    def find_node(namespace, name, node_class, selector)
      target = schemas.xpath("../xs:schema[@targetNamespace='#{namespace}']", ns)
      target = schemas if target.size == 0

      if node = target.at_xpath("xs:#{selector}[@name='#{name.split(':').last}']", ns)
        schema = Schema.from_node(node.at_xpath('parent::xs:schema', ns))
        node_class.new(self, schema, node)
      end
    end
  end
end
