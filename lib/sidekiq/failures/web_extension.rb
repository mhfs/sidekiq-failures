module Sidekiq
  module Failures
    module WebExtension
      LEGACY_SIDEKIQ_VERSION = Gem::Version.new("7.3.9")

      # Helper method to check Sidekiq version
      def self.legacy_sidekiq?
        Gem::Version.new(Sidekiq::VERSION) <= LEGACY_SIDEKIQ_VERSION
      end

      # Helper method to get parameters based on path and parameter name
      def self.fetch_param_value(path, param_name)
        if legacy_sidekiq?
          # For newer Sidekiq, use route_params or url_params based on path
          lambda { |env| env.params[param_name] }
        else
          # For legacy Sidekiq, just use params
          if path.include?(":#{param_name}")
            lambda { |env| env.route_params(param_name.to_sym) }
          else
            lambda { |env| env.url_params(param_name.to_s) }
          end
        end
      end

      # Helper method to handle parse_params vs parse_key compatibility
      def self.parse_key_or_params
        lambda do |env, key|
          if env.respond_to?(:parse_key)
            env.parse_key(key)
          else
            env.parse_params(key)
          end
        end
      end

      # Define the helper method implementation that will be used in both versions
      # Instead of a static lambda, we'll return a method that needs to be evaluated in context
      def self.safe_relative_time_implementation
        lambda do |time, context|
          return unless time

          time = if time.is_a?(Numeric)
            Time.at(time)
          else
            Time.parse(time)
          end

          # Use the context to call relative_time
          context.relative_time(time)
        end
      end

      # Define the helpers module for Sidekiq 8.0+
      module FailuresHelpers
        def safe_relative_time(time)
          # Pass self (the context with relative_time) to the implementation
          WebExtension.safe_relative_time_implementation.call(time, self)
        end
      end

      def self.registered(app)
        view_path = File.join(File.expand_path("..", __FILE__), "views")
        if legacy_sidekiq?
          failures_view_path = File.join(view_path, "failures_legacy.erb")
          failure_view_path = File.join(view_path, "failure_legacy.erb")
        else
          failures_view_path = File.join(view_path, "failures.erb")
          failure_view_path = File.join(view_path, "failure.erb")
        end

        # Create a parse helper for use in routes
        parse_helper = parse_key_or_params

        # Use appropriate helpers implementation based on Sidekiq version
        if legacy_sidekiq?
          # Original implementation for older Sidekiq versions
          app.helpers do
            define_method(:safe_relative_time) do |time|
              # Pass self (the context with relative_time) to the implementation
              WebExtension.safe_relative_time_implementation.call(time, self)
            end
          end
        else
          # New implementation for Sidekiq 8.0+
          app.helpers(FailuresHelpers)
        end

        app.get "/failures" do
          page_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures", "page").call(self)
          count_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures", "count").call(self)
          @count = (count_param || 25).to_i

          (@current_page, @total_size, @failures) = page(LIST_KEY, page_param, @count, :reverse => true)
          @failures = @failures.map {|msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }

          render(:erb, File.read(failures_view_path))
        end

        app.get "/failures/:key" do
          key_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures/:key", "key").call(self)
          halt 404 unless key_param

          @failure = FailureSet.new.fetch(*parse_helper.call(self, key_param)).first
          if @failure.nil?
            redirect "#{root_path}failures"
          else
            render(:erb, File.read(failure_view_path))
          end
        end

        app.post "/failures" do
          key_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures", "key").call(self)
          halt 404 unless key_param

          key_param.each do |key|
            job = FailureSet.new.fetch(*parse_helper.call(self, key)).first
            next unless job

            retry_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures", "retry").call(self)
            if retry_param
              job.retry_failure
            else
              delete_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures", "delete").call(self)
              if delete_param
                job.delete
              end
            end
          end

          redirect_with_query("#{root_path}failures")
        end

        app.post "/failures/:key" do
          key_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures/:key", "key").call(self)
          halt 404 unless key_param

          job = FailureSet.new.fetch(*parse_helper.call(self, key_param)).first
          if job
            retry_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures/:key", "retry").call(self)
            if retry_param
              job.retry_failure
            else
              delete_param = Sidekiq::Failures::WebExtension.fetch_param_value("/failures/:key", "delete").call(self)
              if delete_param
                job.delete
              end
            end
          end
          redirect_with_query("#{root_path}failures")
        end

        app.post "/failures/all/reset" do
          Sidekiq::Failures.reset_failure_count
          redirect "#{root_path}failures"
        end

        app.post "/failures/all/delete" do
          FailureSet.new.clear
          redirect "#{root_path}failures"
        end

        app.post "/failures/all/retry" do
          FailureSet.new.retry_all_failures
          redirect "#{root_path}failures"
        end

        app.get '/filter/failures' do
          redirect "#{root_path}failures"
        end

        app.post '/filter/failures' do
          substr_param = Sidekiq::Failures::WebExtension.fetch_param_value("/filter/failures", "substr").call(self)
          @failures = Sidekiq::Failures::FailureSet.new.scan("*#{substr_param}*")
          @current_page = 1
          @count = @total_size = @failures.count
          render(:erb, File.read(failures_view_path))
        end
      end
    end
  end
end
