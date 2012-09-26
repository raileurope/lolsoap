require 'nokogiri'

module LolSoap
  # @private
  class WSDLParser
    class Type
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

      def elements
        Hash[
          node.xpath('.//xs:element', parser.ns).map do |element|
            max_occurs = element.attribute('maxOccurs').to_s

            [
              prefix_and_name(element.attr('name')).last,
              {
                :type     => prefix_and_name(element.attr('type')).join(':'),
                :singular => max_occurs.empty? || max_occurs == '1'
              }
            ]
          end
        ]
      end

      def prefix_and_name(string)
        parser.prefix_and_name(string, target_namespace)
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
      @endpoint ||= doc.at_xpath('/d:definitions/d:service/d:port/s:address/@location', ns).to_s
    end

    def schemas
      doc.xpath('/d:definitions/d:types/xs:schema', ns)
    end

    def types
      @types ||= begin
        types = {}
        schemas.each do |schema|
          target_namespace = schema.attr('targetNamespace').to_s

          schema.xpath('xs:element[@name] | xs:complexType[@name]', ns).each do |node|
            type = Type.new(self, node, target_namespace)

            types[type.name_with_prefix] = {
              :name     => type.name,
              :prefix   => type.prefix,
              :elements => type.elements
            }
          end
        end
        types
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
  end
end
