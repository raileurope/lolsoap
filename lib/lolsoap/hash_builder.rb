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
      if node.first_element_child
        children_hash
      else
        content
      end
    end

    private

    # @private
    def children_hash
      hash = {}
      node.element_children.each do |child|
        element = type.element(child.name)
        output  = self.class.new(child, element.type).output
        val     = hash[child.name]
        if output
          if val
            if val.is_a?(Array)
              val << output
            else
              hash[child.name] = [val, output]
            end
          else
            hash[child.name] = element.singular? ? output : [output]
          end
        else
          hash[child.name] = element.singular? ? nil : []
        end
      end
      LolSoap::Callbacks.in('hash_builder.after_children_hash').expose(hash, node, type)
      hash
    end

    # @private
    def content
      node.text.to_s unless nil_value?
    end

    # @private
    def nil_value?
      node.attribute_with_ns('nil', 'http://www.w3.org/2001/XMLSchema-instance')
    end
  end
end
