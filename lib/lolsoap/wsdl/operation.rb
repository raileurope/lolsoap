class LolSoap::WSDL
  class Operation
    attr_reader :wsdl, :action, :input

    def initialize(wsdl, action, input)
      @wsdl   = wsdl
      @action = action
      @input  = input
    end

    def inspect
      "<LolSoap::WSDL::Operation " \
      "action=#{action.inspect} " \
      "input=#{input.inspect}>"
    end
  end
end
