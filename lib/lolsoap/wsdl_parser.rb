require 'nokogiri'

module LolSoap
  class WSDLParser
    NS = {
      :wsdl      => 'http://schemas.xmlsoap.org/wsdl/',
      :soap      => 'http://schemas.xmlsoap.org/wsdl/soap12/',
      :xmlschema => 'http://www.w3.org/2001/XMLSchema'
    }

    attr_reader :raw, :doc

    def initialize(raw, xml_parser = Nokogiri::XML::Document)
      @raw = raw
      @doc = xml_parser.parse(raw)
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
        'd' => NS[:wsdl], 'soap' => NS[:soap]
      ).to_s
    end

    def types
      @types ||= begin
        types = doc.xpath(
          '/d:definitions/d:types/s:schema/s:element[@name]',
          '/d:definitions/d:types/s:schema/s:complexType[@name]',
          'd' => NS[:wsdl], 's' => NS[:xmlschema]
        )
        Hash[
          types.map do |type|
            namespace = type.at_xpath('ancestor::s:schema/@targetNamespace', 's' => NS[:xmlschema]).to_s
            elements  = type.xpath('.//s:element', 's' => NS[:xmlschema])
            name      = type.attribute('name').to_s

            [
              name,
              {
                :name      => name,
                :namespace => namespace,
                :elements  => Hash[elements.map { |e| [e.attribute('name').to_s, e.attribute('type').to_s] }]
              }
            ]
          end
        ]
      end
    end

    def messages
      @messages ||= Hash[
        doc.xpath('/d:definitions/d:message', 'd' => NS[:wsdl]).map do |msg|
          element = msg.at_xpath('./d:part/@element', 'd' => NS[:wsdl]).to_s
          [msg.attribute('name').to_s, types[element.split(':').last]]
        end
      ]
    end

    def port_type_operations
      @port_type_operations ||= Hash[
        doc.xpath('/d:definitions/d:portType/d:operation', 'd' => NS[:wsdl]).map do |op|
          input  = op.at_xpath('./d:input/@message',  'd' => NS[:wsdl]).to_s.split(':').last
          output = op.at_xpath('./d:output/@message', 'd' => NS[:wsdl]).to_s.split(':').last
          name   = op.attribute('name').to_s

          [name, { :name => name, :input => messages[input], :output => messages[output] }]
        end
      ]
    end

    def operations
      @operations ||= begin
        binding = doc.at_xpath(
          '/d:definitions/d:service/d:port/soap:address/../@binding',
          'd' => NS[:wsdl], 'soap' => NS[:soap]
        ).to_s.split(':').last

        Hash[
          doc.xpath("/d:definitions/d:binding[@name='#{binding}']/d:operation", 'd' => NS[:wsdl]).map do |op|
            name   = op.attribute('name').to_s
            action = op.at_xpath('./soap:operation/@soapAction', 'soap' => NS[:soap]).to_s

            [name, { :name => name, :action => action, :input => port_type_operations[name][:input] }]
          end
        ]
      end
    end
  end
end
