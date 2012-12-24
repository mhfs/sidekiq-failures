require "sidekiq/web"
require "sidekiq/failures/version"
require "sidekiq/failures/middleware"
require "sidekiq/failures/web_extension"

module Sidekiq

  SIDEKIQ_FAILURES_MODES = ['all', 'exhausted'].freeze

  def self.failures_default_mode=(mode)
    unless SIDEKIQ_FAILURES_MODES.include?(mode.to_s)
      raise ArgumentError, "Sidekiq#failures_default_mode valid options: #{SIDEKIQ_FAILURES_MODES}"
    end
    @failures_default_mode = mode
  end

  def self.failures_default_mode
    @failures_default_mode  || 'all'
  end


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
