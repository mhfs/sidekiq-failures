module Sidekiq
  module Failures
    class Middleware
      attr_accessor :msg

      def call(worker, msg, queue)
        self.msg = msg
        yield
      rescue => e
        raise e if skip_failure?

        data = {
          :failed_at => Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
          :payload => msg,
          :exception => e.class.to_s,
          :error => e.to_s,
          :backtrace => e.backtrace,
          :worker => msg['class'],
          :queue => queue
        }

        Sidekiq.redis { |conn| conn.lpush(:failed, Sidekiq.dump_json(data)) }

        raise e
      end

      private

      def skip_failure?
        msg['failures'] == false || not_exhausted?
      end

      def not_exhausted?
        exhausted_mode? && !last_try?
      end

      def exhausted_mode?
        if msg['failures']
          msg['failures'] == 'exhausted'   
        else
          Sidekiq.failures_default_mode.to_s == 'exhausted'
        end
      end

      def last_try?
        retry_count == max_retries - 1
      end

      def retry_count
        msg['retry_count'] || 0
      end

      def max_retries
        retry_middleware.retry_attempts_from(msg['retry'], default_max_retries)
      end

      def retry_middleware
        @retry_middleware ||= Sidekiq::Middleware::Server::RetryJobs.new
      end

      def default_max_retries
        Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS
      end
    end
  end
end
