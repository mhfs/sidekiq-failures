require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"

require "rack/test"

require "sidekiq"
require "sidekiq-failures"

Celluloid.logger = nil
Sidekiq.logger.level = Logger::ERROR

REDIS = Sidekiq::RedisConnection.create(:url => "redis://localhost/15", :namespace => 'sidekiq_failures_test')
