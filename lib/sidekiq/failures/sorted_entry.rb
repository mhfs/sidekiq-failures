module Sidekiq
  class SortedEntry
    alias_method :super_initialize, :initialize

    def initialize(parent, score, item)
      super_initialize(parent, score, item)

      # 0.3.0 compatibility
      @item.merge!(@item["payload"]) if @item["payload"]
    end

    def retry_failure
      Sidekiq.redis do |conn|
        # from Redis v6.2.0, zrangebyscore is deprecated and zrange with BYSCORE is used
        # option byscore is available from redis-rb v4.6.0
        results = if Gem::Version.new(conn.info["redis_version"].to_s) >= Gem::Version.new('6.2.0') &&
                     Gem.loaded_specs['redis'].version >= Gem::Version.new('4.6.0')
                    conn.zrange(Sidekiq::Failures::LIST_KEY, score.to_i, score.to_i, byscore: true)
                  else
                    conn.zrangebyscore(Sidekiq::Failures::LIST_KEY, score, score)
                  end
        conn.zremrangebyscore(Sidekiq::Failures::LIST_KEY, score, score)
        results.map do |message|
          msg = Sidekiq.load_json(message)
          Sidekiq::Client.push(msg)
        end
      end
    end
  end
end
