require "sidekiq/web"
require "sidekiq/failures/version"
require "sidekiq/failures/middleware"
require "sidekiq/failures/web_extension"

module Sidekiq
  module Failures
  end
end

Sidekiq::Web.register Sidekiq::Failures::WebExtension
Sidekiq::Web.tabs << "Failures"

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Failures::Middleware
  end
end
