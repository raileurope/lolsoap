require 'lolsoap/wsdl'
require 'lolsoap/request'
require 'lolsoap/envelope'
require 'lolsoap/response'

module LolSoap
  class Client
    attr_reader :wsdl, :use_ox

    # @param wsdl a WSDL object, or a string that will be parsed into one
    def initialize(wsdl, use_ox: false)
      @wsdl = wsdl.respond_to?(:to_str) ? WSDL.parse(wsdl.to_str) : wsdl
      @use_ox = use_ox
    end

    # @return [LolSoap::Request] A request for the API action you want to perform
    def request(name)
      Request.new(Envelope.new(wsdl, wsdl.operation(name)))
    end

    # @return [LolSoap::Response] A response object for an API action that has been performed
    def response(request, raw)
      Response.parse(request, raw, use_ox: use_ox)
    end
  end
end
