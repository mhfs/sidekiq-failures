module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)
        app.helpers do
          def find_template(view, *a, &b)
            dir = File.expand_path("../views/", __FILE__)
            super(dir, *a, &b)
            super
          end
        end

        app.get "/failures" do
          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page("failed", params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq.load_json(msg) }

          slim :failures
        end

        app.post "/failures/remove" do
          Sidekiq.redis do |redis|
            redis.del("failed")
            redis.set("stat:failed", 0)
          end

          redirect "#{root_path}failures"
        end
      end
    end
  end
end
