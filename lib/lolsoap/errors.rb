module LolSoap
  class Error < StandardError; end

  class FaultRaised < Error
    attr_reader :fault

    def initialize(fault)
      @fault = fault
    end

    def message
      "#{fault.reason}\n#{fault.detail}"
    end
  end
end
