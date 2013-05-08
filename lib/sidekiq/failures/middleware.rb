module Sidekiq
  module Failures
    class Middleware
      include Sidekiq::Util
      attr_accessor :msg

      def call(worker, msg, queue)
        self.msg = msg
        yield
      rescue Sidekiq::Shutdown
        raise
      rescue => e
        raise e if skip_failure?

        data = {
          :failed_at => Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
          :payload => msg,
          :exception => e.class.to_s,
          :error => e.to_s,
          :backtrace => e.backtrace,
          :worker => msg['class'],
          :processor => "#{hostname}:#{process_id}-#{Thread.current.object_id}:default",
          :queue => queue
        }

        Sidekiq.redis { |conn| conn.lpush(:failed, Sidekiq.dump_json(data)) }

        raise e
      end

      private

      def skip_failure?
        failure_mode == :off || not_exhausted?
      end

      def not_exhausted?
        failure_mode == :exhausted && !last_try?
      end

      def failure_mode
        case msg['failures'].to_s
        when 'true', 'all'
          :all
        when 'false', 'off'
          :off
        when 'exhausted'
          :exhausted
        else
          Sidekiq.failures_default_mode
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
