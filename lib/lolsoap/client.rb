require 'lolsoap/wsdl'
require 'lolsoap/request'
require 'lolsoap/envelope'
require 'lolsoap/response'

module LolSoap
  class Client
    attr_reader :wsdl

    def initialize(wsdl)
      @wsdl = wsdl.respond_to?(:to_str) ? WSDL.parse(wsdl.to_str) : wsdl
    end

    def request(name)
      Request.new(Envelope.new(wsdl, wsdl.operation(name)))
    end

    def response(request, raw)
      Response.parse(request, raw)
    end
  end
end
