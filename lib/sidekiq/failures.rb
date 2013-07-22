begin
  require "sidekiq/web"
rescue LoadError
  # client-only usage
end

require "sidekiq/failures/version"
require "sidekiq/failures/failure_entry"
require "sidekiq/failures/failure_set"
require "sidekiq/failures/middleware"
require "sidekiq/failures/web_extension"

module Sidekiq

  SIDEKIQ_FAILURES_MODES = [:all, :exhausted, :off].freeze

  # Sets the default failure tracking mode.
  #
  # The value provided here will be the default behavior but can be overwritten
  # per worker by using `sidekiq_options :failures => :mode`
  #
  # Defaults to :all
  def self.failures_default_mode=(mode)
    unless SIDEKIQ_FAILURES_MODES.include?(mode.to_sym)
      raise ArgumentError, "Sidekiq#failures_default_mode valid options: #{SIDEKIQ_FAILURES_MODES}"
    end

    @failures_default_mode = mode.to_sym
  end

  # Fetches the default failure tracking mode.
  def self.failures_default_mode
    @failures_default_mode || :all
  end

  # Sets the maximum number of failures to track
  #
  # If the number of failures exceeds this number the list will be trimmed
  # (oldest failures will be purged).
  #
  # Defaults to 1000
  # Set to false to disable rotation
  def self.failures_max_count=(value)
    @failures_max_count = value
  end

  # Fetches the failures max count value
  def self.failures_max_count
    return 1000 if @failures_max_count.nil?

    @failures_max_count
  end

  module Failures
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.insert_before Sidekiq::Middleware::Server::RetryJobs, Sidekiq::Failures::Middleware
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::Failures::WebExtension

  if Sidekiq::Web.tabs.is_a?(Array)
    # For sidekiq < 2.5
    Sidekiq::Web.tabs << "failures"
  else
    Sidekiq::Web.tabs["Failures"] = "failures"
  end
end
