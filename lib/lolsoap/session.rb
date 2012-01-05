module LolSoap
  # client = Client.new(File.read('foo.wsdl'))
  #
  # request = client.request('washHands')
  # request.body do |b|
  #   b.soapScent 'Lemon'
  #   b.duration '5 mins'
  #   ...
  # end
  #
  # http_req = request.http
  # http.post(http_req.url, http_req.headers, http_req.body)
  class Session
    attr_reader :wsdl

    # wsdl - if it responds to to_str, then it's assumed to be the XML WSDL data.
    #        otherwise, assumed to be an object conforming to the public interface of LolSoap::WSDL
    def initialize(wsdl)
      @wsdl = wsdl.respond_to?(:to_str) ? WSDL.new(wsdl.to_str) : wsdl
    end

    def build(action, &block)
      BodyBuilder.new(wsdl, action).define(&block)
    end

    # action - the name of the action to be performed
    # body   - something that returns the body XML when to_s is called on it
    def request(action, body)
      Request.new(wsdl, action, body)
    end

    # raw_response - not sure yet, possibly [status, headers, body] ?
    def response(raw_response)
      Response.new(wsdl, raw_response)
    end
  end
end
