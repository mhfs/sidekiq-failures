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
      rescue Exception => e
        raise e if skip_failure?

        data = {
          :failed_at => Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
          :payload => msg,
          :exception => e.class.to_s,
          :error => e.message,
          :backtrace => e.backtrace,
          :worker => msg['class'],
          :processor => "#{hostname}:#{process_id}-#{Thread.current.object_id}",
          :queue => queue
        }

        Sidekiq.redis do |conn|
          conn.lpush(QUEUE_KEY, Sidekiq.dump_json(data))
          unless Sidekiq.failures_max_count == false
            conn.ltrim(QUEUE_KEY, 0, Sidekiq.failures_max_count - 1)
          end
        end

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
        ! msg['retry'] || retry_count == max_retries - 1
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
