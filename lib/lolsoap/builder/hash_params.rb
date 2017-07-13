require 'lolsoap/wsdl'
require 'byebug'
require 'awesome_print'

module LolSoap::Builder
  # Used to build XML, with namespaces automatically added.
  #
  # @example General
  #   builder = HashParams.new(node, type)
  #   builder.parse(someTag: { foo: 'bar' })
  #   # => <ns1:someTag><ns1:foo>bar</ns1:foo></ns1:someTag>
  #
  # @example Explicitly specifying a namespace prefix
  #   builder = HashParams.new(node, type)
  #   builder.parse({ ns: 'ns2', tag: 'someTag'} => nil)
  #   # => <ns2:someTag/>
  class HashParams

    def initialize(node, type = WSDL::NullType.new)
      @node = node
      @type = type || WSDL::NullType.new
    end

    #

    def parse(hash, node: @node, type: @type)
      # TODO : a before_parse callback
      # -> sort hash with type.elements_names
      # -> replace tag name by @type.elements_names where identical tr('_', '').downcase

      hash.each do |key, val|
        # TODO : avoid this mess by allowing attributes on root elem
        if type.has_attribute?(key.to_s)
          node[key] = val
        else
          make_tag(
            node,
            extract_params!(type, key, val)
          )
        end
      end
    end

    private

    # @private
    # TODO : smells I'm missing an object
    def extract_params!(type, key, val)
      content = sub_hash = hash = nil

      if key.is_a?(Hash)
        name   = key.delete(:tag).to_s
        prefix = key.delete(:ns) || type.element_prefix(name)
        hash   = key
      else
        name   = key.to_s
        prefix = type.element_prefix(name)
      end

      if val.is_a?(Hash)
        sub_hash = val
      else
        content = val
      end

      sub_type = type.sub_type(name)

      { name: name, prefix: prefix, attributes: hash, sub_hash: sub_hash,
        content: content, sub_type: sub_type }
    end

    # @private
    def make_tag(node, prefix:, name:, sub_type:,
                 sub_hash:, content: [], attributes:)

      # TODO : check if we validate with @type.has_attribute?
      args = content
      args << attributes if attributes
      sub_node = node.document.create_element(name, args)
      sub_node.namespace = node.namespace_scopes.find { |n| n.prefix == prefix }
      node << sub_node
      parse(sub_hash, node: sub_node, type: sub_type) if sub_hash
    end
  end
end
