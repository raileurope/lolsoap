module LolSoap
  class Request
    attr_reader :envelope

    def initialize(envelope)
      @envelope = envelope
    end

    def body(&block)
      envelope.body(&block)
    end

    def header(&block)
      envelope.header(&block)
    end

    def soap_namespace
      envelope.soap_namespace
    end

    def url
      envelope.endpoint
    end

    def input_type
      envelope.input_type
    end

    def output_type
      envelope.output_type
    end

    def headers
      {
        'Content-Type'   => 'application/soap+xml;charset=UTF-8',
        'Content-Length' => content.bytesize.to_s,
        'SOAPAction'     => envelope.action
      }
    end

    def content
      @content ||= envelope.to_xml
    end
  end
end
