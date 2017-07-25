# Used to add user processing in definded hooks.
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
  @registered = []

  # Aggregates all callbacks on the selected key to call them.
  class Selected
    def initialize(callbacks = [])
      @callbacks = callbacks
    end

    def expose(*args)
      @callbacks.each { |c| c.call(*args) }
    end
  end

  # Stores, removes and selects the callbacks hashes in the class ivar
  class << self
    def in(key)
      Selected.new(
        @registered.flat_map { |c| c.callbacks[key] }
      )
    end

    def register(*klass)
      @registered |= klass
    end

    def unregister(klass)
      @registered.delete(klass)
    end
  end

  attr_reader :callbacks

  # Manages callbacks in insatances so we can manage sets of callbacks.
  def initialize
    @callbacks = {}
    enable
  end

  # @param key [String] the unique self explanatory name of the hook
  def for(key)
    callbacks[key] ||= []
  end

  def enable
    self.class.register(self)
  end

  def disable
    self.class.unregister(self)
  end
end
