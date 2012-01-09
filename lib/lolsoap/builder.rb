module LolSoap
  class Builder
    attr_reader :node, :type

    def initialize(node, type)
      @node = node
      @type = type
    end

    def __tag__(name, *args)
      sub_type = type.element(name.to_s)
      context  = sub_type.prefix ? node[sub_type.prefix] : node
      sub_node = context.__send__(name, *args)
      builder  = self.class.new(sub_node, sub_type)

      yield builder if block_given?
      builder
    end

    private

    alias method_missing __tag__
  end
end
