require 'lolsoap/wsdl'
require 'byebug'
require 'awesome_print'

class LolSoap::Builder < SimpleDelegator
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
    def content(hash, node: @node, type: @type)
      # TODO : a before_parse callback
      # -> sort hash with type.elements_names
      # -> replace tag name by @type.elements_names where identical tr('_', '').downcase
      hash.each do |key, val|
        make_tag(node, extract_params!(type, key, val))
      end
    end

    # Use when starting from an existing node
    def attributes(hash, node: @node, type: @type)
      hash.each do |key, val|
        node[key] = val
      end
    end

    private

    # @private
    # TODO : smells I'm missing an object
    def extract_params!(type, key, val)
      content = sub_hash = prefix = nil
      
      if val.is_a?(Hash)
        sub_hash = val
      else
        content = val
      end

      if key.is_a?(Hash)
        name   = key.delete(:tag).to_s
        prefix = key.delete(:ns).to_s
        content = *content << key unless key.empty?
      else
        name = key.to_s
      end

      sub_type = type.sub_type(name)

      { name: name, prefix: prefix || type.element_prefix(name), sub_hash: sub_hash,
        content: content, sub_type: sub_type }
    end

    # @private
    def make_tag(node, prefix:, name:, sub_type:,
                 sub_hash:, content: [])

      sub_node = node.document.create_element(name, content)
      sub_node.namespace = node.namespace_scopes.find { |n| n.prefix == prefix }
      node << sub_node
      if sub_hash
        builder = LolSoap::Builder.new(sub_node, sub_type)
        builder.content(sub_hash)
      end
    end
  end
end