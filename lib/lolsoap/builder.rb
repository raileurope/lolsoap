require 'lolsoap/wsdl'

module LolSoap
  class Builder
    RESERVED_METHODS = %w(object_id respond_to_missing? inspect === to_s)

    alias :__class__ :class
    instance_methods.each do |m|
      undef_method m unless RESERVED_METHODS.include?(m.to_s) || m =~ /^__/
    end

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
      @type = type
    end

    def __tag__(name, *args, &block)
      __prefixed_tag__(@type.prefix, @type.element(name.to_s), name, *args, &block)
    end

    def __prefixed_tag__(prefix, sub_type, name, *args)
      sub_node = @node.document.create_element(name.to_s, *args)
      sub_node.namespace = @node.namespace_scopes.find { |n| n.prefix == prefix }

      @node << sub_node

      builder = __class__.new(sub_node, sub_type)
      yield builder if block_given?
      builder
    end

    def __node__
      @node
    end

    def __type__
      @type
    end

    def [](prefix)
      Prefix.new(self, prefix)
    end

    def respond_to?(name)
      true
    end

    private

    alias method_missing __tag__
  end
end
