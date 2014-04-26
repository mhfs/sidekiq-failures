module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)
        view_path = File.join(File.expand_path("..", __FILE__), "views")

        app.get "/failures" do
          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @failures) = page(LIST_KEY, params[:page], @count)
          @failures = @failures.map {|msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }

          render(:erb, File.read(File.join(view_path, "failures.erb")))
        end

        app.get "/failures/:key" do
          halt 404 unless params['key']

          @failure = FailureSet.new.fetch(*parse_params(params['key'])).first
          redirect "#{root_path}failures" if @failure.nil?
          render(:erb, File.read(File.join(view_path, "failure.erb")))
        end

        app.post "/failures" do
          halt 404 unless params['key']

          params['key'].each do |key|
            job = FailureSet.new.fetch(*parse_params(key)).first
            next unless job

            if params['retry']
              job.retry_failure
            elsif params['delete']
              job.delete
            end
          end

          redirect_with_query("#{root_path}failures")
        end

        app.post "/failures/:key" do
          halt 404 unless params['key']

          job = FailureSet.new.fetch(*parse_params(params['key'])).first
          if job
            if params['retry']
              job.retry_failure
            elsif params['delete']
              job.delete
            end
          end
          redirect_with_query("#{root_path}failures")
        end

        app.post "/failures/all/reset" do
          Sidekiq::Failures.reset_failures
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

        app.after do
          if String === response.body
            body hijack_failed(response.body)
          end
        end

        app.helpers do
          def hijack_failed(body)
            body.gsub(
              /<li class="failed(.*?)">(.*?)<\/li>/m,
              "<li class=\"failed\\1\"><a href=\"#{root_path}failures\">\\2</a></li>"
            )
          end
        end
      end

    end
  end
end
