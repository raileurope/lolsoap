module LolSoap
  # Represents a HTTP request containing a SOAP Envelope
  class Request
    attr_reader :envelope

    def initialize(envelope)
      @envelope = envelope
    end

    # @see Envelope#body
    def body(&block)
      envelope.body(&block)
    end

    # @see Envelope#header
    def header(&block)
      envelope.header(&block)
    end

    # Namespace used for SOAP envelope tags
    def soap_namespace
      envelope.soap_namespace
    end

    # URL to be POSTed to
    def url
      envelope.endpoint
    end

    # The type of the element sent in the request body
    def input_type
      envelope.input_type
    end

    # The type of the element that will be received in the response body
    def output_type
      envelope.output_type
    end

    # Headers that must be set when making the request
    def headers
      {
        'Content-Type'   => 'application/soap+xml;charset=UTF-8',
        'Content-Length' => content.bytesize.to_s,
        'SOAPAction'     => envelope.action
      }
    end

    # The content to be sent in the HTTP request
    def content
      @content ||= envelope.to_xml
    end
  end
end
