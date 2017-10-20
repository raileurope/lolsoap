# Used to add user processing in defined hooks.
#
# @example General
#   LolSoap::Callbacks.register({'hash_params.before_build' => [->(args, node, type) {
#       # I want to use snake case !
#       matcher = type.elements.keys.map { |name| name.tr('_', '').downcase }
#       args.each do |h|
#         found_at = matcher.index(h[:name].tr('_', '').downcase)
#         h[:name] = type.elements.keys[found_at] if found_at
#       end
#       # This API accepts the nodes only in the right order.
#       args.sort_by! { |h| type.elements.keys.index(h[:name]) || 1 / 0.0 }
#     }
#   ]})
#
# @example Flush all callbacks
#   LolSoap::Callbacks.flush_callbacks
#
class LolSoap::Callbacks
  # Aggregates all callbacks on the selected key to call them.
  @store = {}

  class Selected
    def initialize(callbacks)
      @callbacks = callbacks || []
    end

    def expose(*args)
      @callbacks.each do |callback|
        callback.call(*args)
      end
    end
  end

  class << self
    attr_accessor :store

    def register(callbacks)
      self.store = callbacks
    end

    def flush_callbacks
      self.store = {}
    end

    def in(key)
      Selected.new(self.store[key])
    end
  end
end
