require "sidekiq/web"
require "sidekiq/processor"
require "sidekiq/failures/version"
require "sidekiq/failures/middleware"
require "sidekiq/failures/web_extension"

module Sidekiq
  module Failures
  end
end

Sidekiq::Web.register Sidekiq::Failures::WebExtension
Sidekiq::Web.tabs << "Failures"

Sidekiq.server_middleware do |chain|
  chain.add Sidekiq::Failures::Middleware
end
