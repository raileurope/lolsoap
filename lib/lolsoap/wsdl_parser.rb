require 'nokogiri'

module LolSoap
  # @private
  class WSDLParser
    class Node
      attr_reader :parser, :node, :target_namespace, :name, :prefix

      def initialize(parser, node, target_namespace)
        @parser           = parser
        @node             = node
        @target_namespace = target_namespace
        @prefix, @name    = prefix_and_name(node.attr('name'))
      end

      def name_with_prefix
        "#{prefix}:#{name}"
      end

      def prefix_and_name(string)
        parser.prefix_and_name(string, target_namespace)
      end
    end

    class Element < Node
      def type
        if complex_type = node.at_xpath('xs:complexType', parser.ns)
          type = Type.new(parser, complex_type, target_namespace)
          {
            :elements   => type.elements,
            :attributes => type.attributes
          }
        else
          prefix_and_name(node.attr('type').to_s).join(':')
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
                :name     => element.name,
                :prefix   => element.prefix,
                :type     => element.type,
                :singular => element.singular
              }
            ]
          end
        ]
      end

      def element_nodes
        node.xpath('*/xs:element | */*/xs:element | xs:complexContent/xs:extension/*/xs:element | xs:complexContent/xs:extension/*/*/xs:element', parser.ns).map { |el| Element.new(parser, el, target_namespace) }
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

    SOAP_1_1 = 'http://schemas.xmlsoap.org/wsdl/soap/'
    SOAP_1_2 = 'http://schemas.xmlsoap.org/wsdl/soap12/'

    attr_reader :doc

    def self.parse(raw)
      new(Nokogiri::XML::Document.parse(raw))
    end

    def initialize(doc)
      @doc = doc
    end

    def namespaces
      @namespaces ||= begin
        namespaces = Hash[doc.collect_namespaces.map { |k, v| [k.sub(/^xmlns:/, ''), v] }]
        namespaces.delete('xmlns')
        namespaces
      end
    end

    # We invert the hash in a deterministic way so that the results are repeatable.
    def prefixes
      @prefixes ||= Hash[namespaces.sort_by { |k, v| k }.uniq { |k, v| v }].invert
    end

    def endpoint
      @endpoint ||= unescape_uri(doc.at_xpath('/d:definitions/d:service/d:port/s:address/@location', ns).to_s)
    end

    def schemas
      doc.xpath('/d:definitions/d:types/xs:schema', ns)
    end

    def types
      @types ||= begin
        types = {}
        each_node('xs:complexType[not(@abstract="true")]') do |node, target_ns|
          type = Type.new(self, node, target_ns)
          types[type.name_with_prefix] = {
            :name       => type.name,
            :prefix     => type.prefix,
            :elements   => type.elements,
            :attributes => type.attributes
          }
        end
        types
      end
    end

    def type(name)
      name = prefix_and_name(name).last
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
          elements[element.name_with_prefix] = {
            :name   => element.name,
            :prefix => element.prefix,
            :type   => element.type
          }
        end
        elements
      end
    end

    def messages
      @messages ||= Hash[
        doc.xpath('/d:definitions/d:message', ns).map do |msg|
          element = msg.at_xpath('./d:part/@element', ns).to_s
          [msg.attribute('name').to_s, prefix_and_name(element).join(':')]
        end
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
          doc.xpath("/d:definitions/d:binding[@name='#{binding}']/d:operation", ns).map do |op|
            name   = op.attribute('name').to_s
            action = op.at_xpath('./s:operation/@soapAction', ns).to_s

            [
              name,
              {
                :action => action,
                :input  => port_type_operations.fetch(name)[:input],
                :output => port_type_operations.fetch(name)[:output]
              }
            ]
          end
        ]
      end
    end

    def soap_version
      @soap_version ||= namespaces.values.include?(SOAP_1_2) ? '1.2' : '1.1'
    end

    def ns
      @ns ||= {
        'd'  => 'http://schemas.xmlsoap.org/wsdl/',
        'xs' => 'http://www.w3.org/2001/XMLSchema',
        's'  => soap_version == '1.2' ? SOAP_1_2 : SOAP_1_1
      }
    end

    def prefix_and_name(prefixed_name, default_namespace = nil)
      prefix, name = prefixed_name.to_s.split(':')

      if name
        # Ensure we always use the same prefix for a given namespace
        prefix = prefixes.fetch(namespaces.fetch(prefix))
      else
        name   = prefix
        prefix = prefixes.fetch(default_namespace)
      end

      [prefix, name]
    end

    def each_node(xpath)
      schemas.each do |schema|
        target_namespace = schema.attr('targetNamespace').to_s

        schema.xpath(xpath, ns).each do |node|
          yield node, target_namespace
        end
      end
    end

    private

    def unescape_uri(str)
      uri_parser =  URI.const_defined?(:Parser) ? URI::Parser.new : URI

      uri_parser.unescape(str)
    end
  end
end

