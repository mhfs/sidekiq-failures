require "test_helper"

module Sidekiq
  describe Failures do
    describe '.retry_middleware_class' do
      it 'returns based on Sidekiq::VERISON' do
        case Sidekiq::VERSION[0]
        when '5'
          assert_equal Failures.retry_middleware_class, Sidekiq::JobRetry
        when '4'
          assert_equal Failures.retry_middleware_class, Sidekiq::Middleware::Server::RetryJobs
        end
      end
    end
  end
end
