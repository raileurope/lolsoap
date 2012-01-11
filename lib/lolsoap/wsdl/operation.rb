class LolSoap::WSDL
  class Operation
    attr_reader :wsdl, :action, :input, :output

    def initialize(wsdl, action, input, output)
      @wsdl   = wsdl
      @action = action
      @input  = input
      @output = output
    end

    def inspect
      "<LolSoap::WSDL::Operation " \
      "action=#{action.inspect} " \
      "input=#{input.inspect}>"
    end
  end
end
