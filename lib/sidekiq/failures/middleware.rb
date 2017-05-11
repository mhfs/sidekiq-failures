module Sidekiq
  module Failures

    class Middleware
      attr_accessor :msg

      def call(worker, msg, queue)
        self.msg = msg
        yield
      rescue Sidekiq::Shutdown
        raise
      rescue Exception => e
        raise e if skip_failure?

        msg['error_message'] = e.message
        msg['error_class'] = e.class.name
        msg['processor'] = identity
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
          conn.zadd(LIST_KEY, Time.now.utc.to_f, payload)
          unless Sidekiq.failures_max_count == false
            conn.zremrangebyrank(LIST_KEY, 0, -(Sidekiq.failures_max_count + 1))
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
        retry_middleware.send(:retry_attempts_from, msg['retry'], default_max_retries)
      end

      def retry_middleware
        @retry_middleware ||=
          Sidekiq::Failures.retry_middleware_class.new
      end

      def default_max_retries
        Sidekiq::Failures.retry_middleware_class::DEFAULT_MAX_RETRY_ATTEMPTS
      end

      def hostname
        Socket.gethostname
      end

      def identity
        @@identity ||= "#{hostname}:#{$$}"
      end
    end
  end
end
