Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"

require "rack/test"

require "sidekiq"

if Sidekiq::VERSION < '4'
  require 'celluloid'
else
  module Celluloid
    def self.logger=(*); end

    def self.boot; end

    module Thread; end
  end
end

require "sidekiq-failures"
require "sidekiq/processor"
require "sidekiq/fetch"
require "sidekiq/cli"

Celluloid.logger = nil
Sidekiq.logger.level = Logger::ERROR

REDIS = Sidekiq::RedisConnection.create(:url => "redis://localhost/15", :namespace => 'sidekiq_failures_test')
