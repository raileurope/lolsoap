require 'lolsoap/wsdl'
require 'lolsoap/builder/hash_params'
require 'lolsoap/builder/block_params'

module LolSoap
  # Instanciate the class adapted to params
  class Builder < SimpleDelegator
    def initialize(node, type)
      if block_given?
        yield super(BlockParams.new(node, type))
      else
        super(HashParams.new(node, type))
      end
    end
  end
end