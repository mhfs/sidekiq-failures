module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)

        app.before do
          locale = request.env["HTTP_ACCEPT_LANGUAGE"][0,2] if request.env["HTTP_ACCEPT_LANGUAGE"]
          I18n.locale = locale || 'en'

          if app.tabs.is_a?(Array)
            # For sidekiq < 2.5
            app.tabs << "failures"
          else
            app.tabs[I18n.t('sidekiq.extension.failures.tab')] = "failures"
          end
        end

        app.get "/failures" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page("failed", params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq.load_json(msg) }

          render(:slim, File.read(File.join(view_path, "failures.slim")))
        end

        app.post "/failures/remove" do
          Sidekiq.redis {|c|
            c.multi do
              c.del("failed")
              c.set("stat:failed", 0) if params["counter"]
            end
          }

          redirect "#{root_path}failures"
        end
      end
    end
  end
end
