require 'lolsoap/wsdl'
require 'lolsoap/builder/hash_params'
require 'lolsoap/builder/block_params'

module LolSoap
  # Decorator
  class Builder < SimpleDelegator
    def initialize(node, type = WSDL::NullType.new)
      type ||= WSDL::NullType.new

      if block_given?
        yield super(BlockParams.new(node, type))
      else
        super(HashParams.new(node, type))
      end
    end

  end
end