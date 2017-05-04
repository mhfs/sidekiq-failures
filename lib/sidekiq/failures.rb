begin
  require "sidekiq/web"
rescue LoadError
  # client-only usage
end

require "sidekiq/api"
require "sidekiq/failures/version"
require "sidekiq/failures/sorted_entry"
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
  # If the number of failures exceeds this number the list will be trimmed (oldest
  # failures will be purged).
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
    LIST_KEY = :failed

    def self.reset_failures
      Sidekiq.redis { |c| c.set("stat:failed", 0) }
    end

    def self.count
      Sidekiq.redis {|r| r.zcard(LIST_KEY) }
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    # Supports Ruby 1.9 +
    # Sidekiq 5.0.0 removes `Sidekiq::Middleware::Server::RetryJobs` so we simple add
    # the Sidekiq::Failures::Middleware in top of stack
    if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('5.0.0')
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Sidekiq::Failures::Middleware
        end
      end
    else
      chain.insert_before Sidekiq::Middleware::Server::RetryJobs,
                          Sidekiq::Failures::Middleware
    end
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::Failures::WebExtension
  Sidekiq::Web.tabs["Failures"] = "failures"
  Sidekiq::Web.settings.locales << File.join(File.dirname(__FILE__), "failures/locales")
end
