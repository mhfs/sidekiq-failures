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
      
        unless Sidekiq::Failures.record_after_max_retries && retries_pending?(msg)
          Sidekiq.redis { |conn| conn.lpush(:failed, Sidekiq.dump_json(data)) }
        end

        raise
      end

      private 

      def retries_pending? msg
        retry_count(msg) < retry_attempts(msg)
      end

      def retry_count msg
        msg['retry_count'] || 0
      end

      def retry_attempts msg
        Sidekiq::Middleware::Server::RetryJobs.new.retry_attempts_from(msg['retry'], 
          Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS)
      end
    end
  end
end
