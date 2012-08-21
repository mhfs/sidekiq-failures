module Sidekiq
  module Failures
    class Middleware
      def call(worker, msg, queue)
        yield
      rescue => e
        data = {
          :failed_at => Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
          :payload => msg,
          :exception => e.class.to_s,
          :error => e.to_s,
          :backtrace => e.backtrace,
          :worker => msg['class'],
          :queue => queue
        }

        Sidekiq.redis { |conn| conn.rpush(:failed, Sidekiq.dump_json(data)) }

        raise
      end
    end
  end
end
