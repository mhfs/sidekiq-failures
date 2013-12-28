module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)
        app.get "/failures" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page("failed", params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq.load_json(msg) }

          render(:erb, File.read(File.join(view_path, "failures.erb")))
        end

        app.post "/failures/remove" do
          Sidekiq::Failures.reset_failures(counter: params["counter"])

          redirect "#{root_path}failures"
        end
      end
    end
  end
end
