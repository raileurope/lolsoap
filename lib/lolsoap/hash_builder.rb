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
      hash = {}
      children.each do |child|
        element = type.element(child.name)
        output  = self.class.new(child, element.type).output

        if Array === hash[child.name] || !element.singular?
          hash[child.name] ||= []
          hash[child.name] << output
        else
          if hash.include?(child.name)
            hash[child.name] = [hash[child.name]]
            hash[child.name] << output
          else
            hash[child.name] = output
          end
        end
      end
      hash
    end
  end
end
