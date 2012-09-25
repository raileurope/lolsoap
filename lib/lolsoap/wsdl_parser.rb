require 'nokogiri'

module LolSoap
  # @private
  class WSDLParser
    NS = {
      :wsdl      => 'http://schemas.xmlsoap.org/wsdl/',
      :soap      => 'http://schemas.xmlsoap.org/wsdl/soap/',
      :soap12    => 'http://schemas.xmlsoap.org/wsdl/soap12/',
      :xmlschema => 'http://www.w3.org/2001/XMLSchema'
    }

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

    def endpoint
      @endpoint ||= doc.at_xpath(
        '/d:definitions/d:service/d:port/soap:address/@location',
        'd' => ns[:wsdl], 'soap' => ns[:soap]
      ).to_s
    end

    def types
      @types ||= begin
        types = doc.xpath(
          '/d:definitions/d:types/s:schema/s:element[@name]',
          '/d:definitions/d:types/s:schema/s:complexType[@name]',
          'd' => ns[:wsdl], 's' => ns[:xmlschema]
        )
        Hash[
          types.map do |type|
            namespace = type.at_xpath('ancestor::s:schema/@targetNamespace', 's' => ns[:xmlschema]).to_s
            elements  = type.xpath('.//s:element', 's' => ns[:xmlschema])
            name      = type.attribute('name').to_s

            [
              name,
              {
                :name      => name,
                :namespace => namespace,
                :elements  => Hash[elements.map { |e| [e.attribute('name').to_s, element_hash(e)] }]
              }
            ]
          end
        ]
      end
    end

    def messages
      @messages ||= Hash[
        doc.xpath('/d:definitions/d:message', 'd' => ns[:wsdl]).map do |msg|
          element = msg.at_xpath('./d:part/@element', 'd' => ns[:wsdl]).to_s
          [msg.attribute('name').to_s, types[element.split(':').last]]
        end
      ]
    end

    def port_type_operations
      @port_type_operations ||= Hash[
        doc.xpath('/d:definitions/d:portType/d:operation', 'd' => ns[:wsdl]).map do |op|
          input  = op.at_xpath('./d:input/@message',  'd' => ns[:wsdl]).to_s.split(':').last
          output = op.at_xpath('./d:output/@message', 'd' => ns[:wsdl]).to_s.split(':').last
          name   = op.attribute('name').to_s

          [name, { :name => name, :input => messages[input], :output => messages[output] }]
        end
      ]
    end

    def operations
      @operations ||= begin
        binding = doc.at_xpath(
          '/d:definitions/d:service/d:port/soap:address/../@binding',
          'd' => ns[:wsdl], 'soap' => ns[:soap]
        ).to_s.split(':').last

        Hash[
          doc.xpath("/d:definitions/d:binding[@name='#{binding}']/d:operation", 'd' => ns[:wsdl]).map do |op|
            name   = op.attribute('name').to_s
            action = op.at_xpath('./soap:operation/@soapAction', 'soap' => ns[:soap]).to_s

            [
              name,
              {
                :name   => name,
                :action => action,
                :input  => port_type_operations[name][:input],
                :output => port_type_operations[name][:output]
              }
            ]
          end
        ]
      end
    end

    private

    def element_hash(el)
      max_occurs = el.attribute('maxOccurs').to_s
      {
        :name     => el.attribute('name').to_s,
        :type     => el.attribute('type').to_s,
        :singular => max_occurs.empty? || max_occurs == '1'
      }
    end

    def ns
      @ns ||= begin
        ns = { :wsdl => NS[:wsdl], :xmlschema => NS[:xmlschema] }

        if namespaces.values.include?(NS[:soap12])
          ns[:soap] = NS[:soap12]
        else
          ns[:soap] = NS[:soap]
        end

        ns
      end
    end
  end
end
