module LolSoap
  # Represents a HTTP request containing a SOAP Envelope
  class Request
    extend Forwardable

    attr_reader   :envelope
    attr_accessor :xml_options

    def initialize(envelope)
      @envelope    = envelope
      @xml_options = default_xml_options
    end

    # @see Envelope
    def_delegators :envelope, :builder=, :body, :header, :soap_namespace

    # URL to be POSTed to
    def_delegator :envelope, :endpoint, :url

    # The SOAP version in use, private method
    def soap_version
      envelope.soap_version
    end

    # The type of the element sent in the request body
    def_delegator :envelope, :input_body_content_type, :input_type

    # The type of the element that will be received in the response body
    def_delegator :envelope, :output_body_content_type, :output_type

    # The MIME type of the request. This is always application/soap+xml,
    # but it could be overridden in a subclass.
    def mime
      if soap_version == '1.1'
        'text/xml'
      else
        'application/soap+xml'
      end
    end

    # The charset of the request. This is always UTF-8, but it could be
    # overridden in a subclass.
    def charset
      'UTF-8'
    end

    # The full content type of the request, assembled from the #mime and
    # #charset.
    def content_type
     "#{mime};charset=#{charset}"
    end

    # Headers that must be set when making the request
    def headers
      {
        'Content-Type'   => content_type,
        'Content-Length' => content.bytesize.to_s,
        'SOAPAction'     => envelope.action
      }
    end

    # The content to be sent in the HTTP request
    def content
      @content ||= envelope.to_xml(xml_options)
    end

    private

    def default_xml_options
      { encoding: charset }
    end
  end
end
