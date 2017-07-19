require 'lolsoap/wsdl'

class LolSoap::Builder < SimpleDelegator
  # Used to build XML, with namespaces automatically added.
  #
  # @example General
  #   builder = HashParams.new(node, type)
  #   builder.content(someTag: { foo: 'bar' })
  #   # => <ns1:someTag><ns1:foo>bar</ns1:foo></ns1:someTag>
  #
  # @example Explicitly specifying a namespace prefix
  #   builder = HashParams.new(node, type)
  #   builder.content([:ns2, :someTag])
  #   # => <ns2:someTag/>
  #
  # @example With attributes
  #   builder = HashParams.new(node, type)
  #   builder.content([:someTag, id: 42] => 'bar')
  #   # => <ns1:someTag id=42>bar</ns1:someTag>
  #

  # TODO : test after fixing mocks in test_builder  
  # @example Mixing hashes and blocks
  #   builder = HashParams.new(node, type)
  #   builder.content(someTag: Proc.new do |t|
  #     t.foo  'bar'
  #   end)
  #
  #   # => <ns1:someTag><ns1:foo>bar</ns1:foo></ns1:someTag>
  #

  class HashParams
    def initialize(node, type = WSDL::NullType.new)
      @node = node
      @type = type || WSDL::NullType.new
    end

    #
    def content(hash)
      # TODO : a before_parse callback working on a parsed hash
      # -> sort hash with type.elements_names
      # -> replace tag name by @type.elements_names where identical tr('_', '').downcase
      hash.each do |key, val|
        make_tag(parse_hash(key, val))
      end
    end

    # Use when starting from an existing node
    def attributes(hash)
      hash.each do |key, val|
        @node[key] = val
      end
    end

    # @private
    def make_tag(name:, prefix: @type.element_prefix(name),
                 sub_hash: nil, args: [], block: nil)
      sub_node = @node.document.create_element(name, *args)
      sub_node.namespace = @node.namespace_scopes.find { |n| n.prefix == prefix }

      @node << sub_node

      LolSoap::Builder.new(sub_node, @type.sub_type(name), &block).tap do |builder|
        builder.content(sub_hash) if sub_hash
      end
    end

    private

    def parse_val(val, params: { args: [] })
      if val.is_a?(Hash)
        params[:sub_hash] = val
      elsif val.is_a?(Proc)
        params[:block] = val
      else
        params[:args] << val
      end
      params
    end

    def extract_key(key, params)
      last = key.pop
      if last.is_a?(Hash)
        params[:args] << last
        params[:name] = key.pop.to_s
      else
        params[:name] = last.to_s
      end
      params[:prefix] = key[0] unless key.empty?
    end

    def parse_key(key, params: { args: [] })
      if key.is_a?(Array)
        extract_key(key, params)
      else
        params[:name] = key.to_s
      end
      params
    end

    def parse_hash(key, val)
      parse_key(
        key, params: parse_val(val)
      )
    end
  end
end