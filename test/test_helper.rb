Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"

# FIXME Remove once https://github.com/mperham/sidekiq/pull/548 is released.
class String
  def blank?
    self !~ /[^[:space:]]/
  end
end

require "rack/test"

require "sidekiq"
require "sidekiq-failures"
require "sidekiq/processor"
require "sidekiq/fetch"

Celluloid.logger = nil
Sidekiq.logger.level = Logger::ERROR

REDIS = Sidekiq::RedisConnection.create(:url => "redis://localhost/15", :namespace => 'sidekiq_failures_test')
