# Used to add user processing in defined hooks.
#
# @example General
#  bing_ads_callbacks = LolSoap::Callbacks.new
#  bing_ads_callbacks.for('hash_params.before_build') << lambda do |args, node, type|
#    # I want to use snake case !
#    matcher = type.elements.keys.map { |name| name.tr('_', '').downcase }
#    args.each do |h|
#      found_at = matcher.index(h[:name].tr('_', '').downcase)
#      h[:name] = type.elements.keys[found_at] if found_at
#    end
#    # This API accepts the nodes only in the right order.
#    args.sort_by! { |h| type.elements.keys.index(h[:name]) || 1 / 0.0 }
#  end
#
# @example Managing callback sets
# bing_ads_callbacks.disable
# google_ads_callbacks.enable
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
