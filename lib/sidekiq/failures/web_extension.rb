module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)
        app.get "/failures" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page("failed", params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq.load_json(msg) }

          if Sidekiq::VERSION < "2.14.0"
            render(:slim, File.read(File.join(view_path, "failures.slim")))
          else
            render(:erb, File.read(File.join(view_path, "failures.erb")))
          end
        end

        app.post "/failures/retries" do
          Sidekiq.redis do |c|
            raw_jobs = []

            c.multi do
              params["ids"].each do |id|
                raw_jobs << c.lindex("failed", id.to_i)
              end
            end

            begin
            raw_jobs.each do |raw_job|
              job = Sidekiq.load_json(raw_job.value)

              payload = job["payload"]
              payload.delete("retry_count")
              payload["retried_at"] = Time.now.utc

              Sidekiq::Client.push(payload.merge("queue" => job["queue"]))
              c.lrem("failed", 1, raw_job.value)
            end
            rescue Exception => e
              puts "#{e.class.to_s}: #{e.message}"
            end
          end

          redirect "#{root_path}failures"
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
