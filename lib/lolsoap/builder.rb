require 'lolsoap/wsdl'

module LolSoap
  # Used to build XML, with namespaces automatically added.
  #
  # @example General
  #   builder = Builder.new(node, type)
  #   builder.someTag do |t|
  #     t.foo 'bar'
  #   end
  #   # => <ns1:someTag><ns1:foo>bar</ns1:foo></ns1:someTag>
  #
  # @example Explicitly specifying a namespace prefix
  #   builder = Builder.new(node, type)
  #   builder['ns2'].someTag
  #   # => <ns2:someTag/>
  class Builder
    RESERVED_METHODS = %w(object_id respond_to_missing? inspect === to_s)

    alias :__class__ :class
    instance_methods.each do |m|
      undef_method m unless RESERVED_METHODS.include?(m.to_s) || m =~ /^__/
    end

    # @private
    class Prefix
      instance_methods.each do |m|
        undef_method m unless RESERVED_METHODS.include?(m.to_s) || m =~ /^__/
      end

      def initialize(owner, prefix)
        @owner  = owner
        @prefix = prefix
      end

      def respond_to?(name)
        true
      end

      private

      def method_missing(*args, &block)
        @owner.__prefixed_tag__(@prefix, LolSoap::WSDL::NullType.new, *args, &block)
      end
    end

    def initialize(node, type = WSDL::NullType.new)
      @node = node
      @type = type || WSDL::NullType.new
    end

    # Add a tag manually, rather than through method_missing. This is so you can still
    # add tags for the very small number of tags that are also existing methods.
    def __tag__(name, *args, &block)
      __prefixed_tag__(@type.element_prefix(name.to_s), @type.sub_type(name.to_s), name, *args, &block)
    end

    def __attribute__(name, value)
      @node[name.to_s] = value.to_s
    end

    def __content__(value)
      @node.content = value
    end

    # @private
    def __prefixed_tag__(prefix, sub_type, name, *args)
      sub_node = @node.document.create_element(name.to_s, *args)
      sub_node.namespace = @node.namespace_scopes.find { |n| n.prefix == prefix }

      # Nokogiri doesn't currently allow to add a child element without a
      # namespace to a parent with a namespace: the child inherits the parent's
      # namespace.  It's a known issue:
      # https://github.com/sparklemotion/nokogiri/issues/1469 Until it's fixed,
      # we'll use this workaround: store the parent's namespace, set it to nil
      # temporarily, add the child and re-add the original namespace to the
      # parent.
      if sub_node.namespace.nil?
        parent_namespace = @node.namespace
        @node.namespace = nil
        @node << sub_node
        @node.namespace = parent_namespace
      else
        @node << sub_node
      end

      builder = __class__.new(sub_node, sub_type)
      yield builder if block_given?
      builder
    end

    # Node accessor. Named to prevent method_missing conflict.
    def __node__
      @node
    end

    # Type accessor. Named to prevent method_missing conflict.
    def __type__
      @type
    end

    # Specify a namespace prefix explicitly
    def [](prefix)
      Prefix.new(self, prefix)
    end

    def respond_to?(name)
      true
    end

    def pretty_print(pp)
      pp.group(2, "#(LolSoap::Builder #{sprintf("0x%x", object_id)} {", "})") do
        pp.pp @node
      end
    end

    private

    # alias method_missing __tag__
    def method_missing(name, *args, &block)
      if @type.has_attribute?(name.to_s)
        __attribute__(name, *args)
      else
        __tag__(name, *args, &block)
      end
    end
  end
end
