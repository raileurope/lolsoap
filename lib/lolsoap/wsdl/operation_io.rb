class LolSoap::WSDL
  class OperationIO
    attr_reader :header, :body

    def initialize(header, body)
      @header = header
      @body   = body
    end

    def inspect
      "<#{self.class} " \
      "header=#{header.inspect} " \
      "body=#{body.inspect}>"
    end
  end
end
