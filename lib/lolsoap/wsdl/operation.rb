class LolSoap::WSDL
  class Operation
    attr_reader :wsdl, :name, :action, :input, :output

    def initialize(wsdl, name, action, input, output)
      @wsdl   = wsdl
      @name   = name
      @action = action
      @input  = input
      @output = output
    end

    def inspect
      "<#{self.class} " \
      "name=#{name.inspect} " \
      "action=#{action.inspect} " \
      "input=#{input.inspect}>"
    end
  end
end
