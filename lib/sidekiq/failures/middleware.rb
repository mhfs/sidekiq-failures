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

        msg['error_message'] = e.message
        msg['error_class'] = e.class.name
        msg['processor'] = "#{hostname}:#{process_id}-#{Thread.current.object_id}"
        msg['failed_at'] = Time.now.utc.to_f

        if msg['backtrace'] == true
          msg['error_backtrace'] = e.backtrace
        elsif msg['backtrace'] == false
          # do nothing
        elsif msg['backtrace'].to_i != 0
          msg['error_backtrace'] = e.backtrace[0..msg['backtrace'].to_i]
        end

        payload = Sidekiq.dump_json(msg)
        Sidekiq.redis do |conn|
          conn.zadd('failure', Time.now.utc.to_f, payload)
          unless Sidekiq.failures_max_count == false
            conn.zremrangebyrank('failure', 0, -(Sidekiq.failures_max_count + 1))
          end
        end

        raise e
      end

      private

      def failure_mode_off?
        failure_mode == :off
      end

      def failure_mode_exhausted?
        failure_mode == :exhausted
      end

      def skip_failure?
        failure_mode_off? || failure_mode_exhausted? && !exhausted?
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

      def exhausted?
        !retriable? || retry_count >= max_retries
      end

      def retriable?
        msg['retry']
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
