require "sidekiq/web"
require "sidekiq/failures/version"
require "sidekiq/failures/middleware"
require "sidekiq/failures/web_extension"

module Sidekiq
  module Failures
  end
end

Sidekiq::Web.register Sidekiq::Failures::WebExtension

if Sidekiq::Web.tabs.is_a?(Array)
  # For sidekiq < 2.5
  Sidekiq::Web.tabs << "failures"
else
  Sidekiq::Web.tabs["Failures"] = "failures"
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Failures::Middleware
  end
end
