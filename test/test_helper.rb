$TESTING = true

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"

require "rack/test"

require "sidekiq"
require "sidekiq-pro" if ENV['SIDEKIQ_PRO_VERSION']
require "sidekiq-failures"
require "sidekiq/processor"
require "sidekiq/fetch"
require "sidekiq/cli"

Sidekiq.logger.level = Logger::ERROR

REDIS = Sidekiq::RedisConnection.create(url: "redis://127.0.0.1:6379/0")
