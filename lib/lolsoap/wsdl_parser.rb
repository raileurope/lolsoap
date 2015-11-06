require 'nokogiri'
require 'cgi'

module LolSoap
  # @private
  class WSDLParser
    class Node
      attr_reader :parser, :node, :target_namespace, :name, :namespace

      def initialize(parser, node, target_namespace)
        @parser           = parser
        @node             = node
        @target_namespace = target_namespace
        @namespace, @name = parser.namespace_and_name(node, node.attr('name').to_s, target_namespace)
      end

      def id
        [namespace, name]
      end
    end

    class Element < Node
      def type
        if complex_type = node.at_xpath('xs:complexType', parser.ns)
          type = Type.new(parser, complex_type, target_namespace)
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

      private

      def max_occurs
        @max_occurs ||= node.attribute('maxOccurs').to_s
      end
    end

    class Type < Node
      def elements
        parent_elements.merge(own_elements)
      end

      def attributes
        parent_attributes + own_attributes
      end

      def base_type
        @base_type ||= begin
          if extension = node.at_xpath('*/xs:extension/@base', parser.ns)
            parser.type(extension.to_s)
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
          Element.new(parser, el, target_namespace)
        }
      end

      def parent_elements
        base_type ? base_type.elements : {}
      end

      def own_attributes
        node.xpath('xs:attribute/@name | */xs:extension/xs:attribute/@name', parser.ns).map(&:text)
      end

      def parent_attributes
        base_type ? base_type.attributes : []
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
        @input ||= OperationIO.new(
          header(:input),
          body(:input)
        )
      end

      def output
        @output ||= OperationIO.new(
          header(:output),
          body(:output)
        )
      end

      private

      def port_type_operation
        parser.port_type_operations.fetch(name)
      end

      def header(direction)
        header_node = node.at_xpath("./d:#{direction}/s:header", parser.ns)
        if header_node && message = header_node["message"]
          parts = parser.messages.fetch(message.to_s.split(':').last)
          parts[header_node['part']] || parts.values.first
        end
      end

      def body(direction)
        parts     = port_type_operation[direction]
        body_node = node.at_xpath("d:#{direction}/s:body", parser.ns)
        parts[body_node['part'] || body_node['parts']] || parts.values.first
      end
    end

    class OperationIO < Struct.new(:header, :body)
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
        each_node('xs:complexType[not(@abstract="true")]') do |node, target_ns|
          type = Type.new(self, node, target_ns)
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

    def type(name)
      name = name.split(":").last
      if node = doc.at_xpath("//xs:complexType[@name='#{name}']", ns)
        target_namespace = node.at_xpath('parent::xs:schema/@targetNamespace', ns).to_s
        Type.new(self, node, target_namespace)
      end
    end

    def elements
      @elements ||= begin
        elements = {}
        each_node('xs:element') do |node, target_ns|
          element = Element.new(self, node, target_ns)
          elements[element.id] = {
            :name      => element.name,
            :namespace => element.namespace,
            :type      => element.type
          }
        end
        elements
      end
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
          input  = op.at_xpath('./d:input/@message',  ns).to_s.split(':').last
          output = op.at_xpath('./d:output/@message', ns).to_s.split(':').last
          name   = op.attribute('name').to_s

          [name, { :input => messages.fetch(input), :output => messages.fetch(output) }]
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
        namespace = node.namespaces.fetch("xmlns:#{prefix}")
      else
        name      = prefixed_name
        namespace = default_namespace
      end

      [namespace, name]
    end

    def each_node(xpath)
      schemas.each do |schema|
        target_namespace = schema.attr('targetNamespace').to_s

        schema.xpath(xpath, ns).each do |node|
          yield node, target_namespace
        end
      end
    end
  end
end

