module Sidekiq
  module Failures
    module WebExtension
      def self.registered(app)
        app.helpers Paginator

        view_path = File.join(File.expand_path("..", __FILE__), "views")

        app.get "/failures" do
          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @failures) = paginate("failure", params[:page], @count)
          @failures = @failures.map { |msg, score| [Sidekiq.load_json(msg), score] }

          render(:slim, File.read(File.join(view_path, "failures.slim")))
        end

        app.get "/failures/:key" do
          halt 404 unless params['key']

          @failure = FailureSet.new.fetch(*parse_params(params['key'])).first
          redirect "#{root_path}failures" if @failure.nil?
          render(:slim, File.read(File.join(view_path, "failure.slim")))
        end

        app.post "/failures" do
          halt 404 unless params['key']

          params['key'].each do |key|
            job = FailureSet.new.fetch(*parse_params(key)).first
            if params['retry']
              job.retry_failure
            elsif params['delete']
              job.delete
            end
          end
          redirect "#{root_path}failures"
        end

        app.post "/failures/:key" do
          halt 404 unless params['key']

          job = FailureSet.new.fetch(*parse_params(params['key'])).first
          if params['retry']
            job.retry_failure
          elsif params['delete']
            job.delete
          end
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
      end
    end
  end
end
