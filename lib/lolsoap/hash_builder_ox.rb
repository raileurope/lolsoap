module LolSoap
  class HashBuilderOx
    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    def output
      #require 'pry'; binding.pry
      if content&.first&.last.is_a? Hash
        content.first.last
      else
        content
      end
    end

    private

    # @private
    def content
      # need some nil check?
      @content ||= complete_hash['Envelope'].find { |x| x.keys.include?('Body') }['Body']
    end

    def complete_hash
      Ox.load(raw, { mode: :hash, strip_namespace: true, symbolize_keys: false })
    end
  end
end
