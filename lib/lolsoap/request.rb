module LolSoap
  class Request
    attr_reader :envelope

    def initialize(envelope)
    end

    def body(&block)
      envelope.body(&block)
    end

    def header(&block)
      envelope.header(&block)
    end

    def http
      # return an object representing the HTTP request
    end
  end
end
