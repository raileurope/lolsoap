module LolSoap
  # Turns an XML node into a hash data structure. Works out which elements
  # are supposed to be collections based on the type information.
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
        content
      end
    end

    def children
      @children ||= node.children.select(&:element?)
    end

    private

    # @private
    def children_hash
      hash = {}
      children.each do |child|
        element = type.element(child.name)
        output  = self.class.new(child, element.type).output

        if !element.singular?
          hash[child.name] ||= []
        end

        if hash.include?(child.name) && !(Array === hash[child.name])
          hash[child.name] = [hash[child.name]]
        end

        if Array === hash[child.name]
          hash[child.name] << output unless output.nil?
        else
          hash[child.name] = output
        end
      end
      hash
    end

    # @private
    def content
      node.text.to_s unless nil_value?
    end

    # @private
    def nil_value?
      parent.search('./*[@xsi:nil=1]', 'xsi' => "http://www.w3.org/2001/XMLSchema-instance").include?(node)
    end

    # @private
    def parent
      node.ancestors.first
    end
  end
end
