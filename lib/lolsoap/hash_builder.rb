module LolSoap
  class HashBuilder
    attr_reader :node, :type

    def initialize(node, type)
      @node = node
      @type = type
    end

    def output
      if children.any?
        children_hash
      else
        node.text.to_s
      end
    end

    def children
      @children ||= node.children.select(&:element?)
    end

    private

    def children_hash
      Hash[
        children.map do |child|
          [child.name, self.class.new(child, type).output]
        end
      ]
    end
  end
end
