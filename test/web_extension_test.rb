require "test_helper"
require "sidekiq/web"

module Sidekiq
  describe "WebExtension" do
    include Rack::Test::Methods

    TOKEN = SecureRandom.base64(defined?(Sidekiq::Web::TOKEN_LENGTH) ? Sidekiq::Web::TOKEN_LENGTH : 32).freeze

    def app
      Sidekiq::Web
    end

    before do
      env 'rack.session', { csrf: TOKEN }
      env 'HTTP_X_CSRF_TOKEN', TOKEN
      Sidekiq.redis(&:flushdb)
    end

    it 'can display home with failures tab' do
      get '/'

      _(last_response.status).must_equal 200
      _(last_response.body).must_match(/Sidekiq/)
      _(last_response.body).must_match(/Failures/)
    end

    it 'can display failures page without any failures' do
      get '/failures'
      _(last_response.status).must_equal 200
      _(last_response.body).must_match(/Failed Jobs/)
      _(last_response.body).must_match(/No failed jobs found/)
    end

    it 'has the reset counter form and action' do
      get '/failures'
      _(last_response.body).must_match(/failures\/all\/reset/)
      _(last_response.body).must_match(/Reset Counter/)
    end

    describe 'when there are failures' do
      before do
        @failure = create_sample_failure
        get '/failures'
      end

      it 'should be successful' do
        _(last_response.status).must_equal 200
      end

      it 'can display failures page with failures listed' do
        _(last_response.body).must_match(/Failed Jobs/)
        _(last_response.body).must_match(/HardWorker/)
        _(last_response.body).must_match(/ArgumentError/)
      end

      it 'can reset counter' do
        assert_equal failed_count, "1"

        _(last_response.body).must_match(/HardWorker/)
        post '/failures/all/reset', { authenticity_token: TOKEN }

        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures$/)

        get '/failures'
        _(last_response.status).must_equal 200
        _(last_response.body).must_match(/HardWorker/)

        assert_equal failed_count, "0"
      end

      it 'has the delete all form and action' do
        _(last_response.body).must_match(/failures\/all\/delete/)
        _(last_response.body).must_match(/Delete All/)
      end

      it 'can delete all failures' do
        assert_equal failed_count, "1"

        _(last_response.body).must_match(/HardWorker/)

        post '/failures/all/delete', { authenticity_token: TOKEN }
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures$/)

        get '/failures'
        _(last_response.status).must_equal 200
        _(last_response.body).must_match(/No failed jobs found/)

        assert_equal failed_count, "1"
      end

      it 'has the retry all form and action' do
        _(last_response.body).must_match(/failures\/all\/retry/)
        _(last_response.body).must_match(/Retry All/)
      end

      it 'can retry all failures' do
        assert_equal failed_count, "1"

        _(last_response.body).must_match(/HardWorker/)
        post '/failures/all/retry', { authenticity_token: TOKEN }
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)

        get '/failures'
        _(last_response.status).must_equal 200
        _(last_response.body).must_match(/No failed jobs found/)
      end

      it 'can delete failure from the list' do
        assert_equal failed_count, "1"

        _(last_response.body).must_match(/HardWorker/)

        post '/failures', { authenticity_token: TOKEN, :key => [build_param_key(@failure)], :delete => 'Delete' }
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)

        get '/failures'
        _(last_response.status).must_equal 200
        _(last_response.body).must_match(/No failed jobs found/)
      end

      it 'can retry failure from the list' do
        assert_equal failed_count, "1"

        _(last_response.body).must_match(/HardWorker/)

        post '/failures', { authenticity_token: TOKEN, :key => [build_param_key(@failure)], :retry => 'Retry Now' }
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)

        get '/failures'
        _(last_response.status).must_equal 200
        _(last_response.body).must_match(/No failed jobs found/)
      end

      it 'can handle failures with nil error_message' do
        create_sample_failure(error_message: nil)

        get '/failures'

        _(last_response.status).must_equal 200
      end
    end

    describe 'when there is failure' do
      before do
        @failure = create_sample_failure
        get "/failures/#{build_param_key(@failure)}"
      end

      it 'should be successful' do
        _(last_response.status).must_equal 200
      end

      it 'can display failure page' do
        _(last_response.body).must_match(/Job/)
        _(last_response.body).must_match(/HardWorker/)
        _(last_response.body).must_match(/ArgumentError/)
        _(last_response.body).must_match(/file1/)
      end

      it 'can delete failure' do
        _(last_response.body).must_match(/HardWorker/)

        post "/failures/#{build_param_key(@failure)}", { authenticity_token: TOKEN, :delete => 'Delete' }
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)

        get "/failures/#{build_param_key(@failure)}"
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)
      end

      it 'can retry failure' do
        _(last_response.body).must_match(/HardWorker/)

        post "/failures/#{build_param_key(@failure)}", { authenticity_token: TOKEN, :retry => 'Retry Now' }
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)

        get "/failures/#{build_param_key(@failure)}"
        _(last_response.status).must_equal 302
        _(last_response.location).must_match(/failures/)
      end

      if defined? Sidekiq::Pro
        it 'can filter failure' do
          create_sample_failure
          post '/filter/failures', { authenticity_token: TOKEN, substr: 'new' }

          _(last_response.status).must_equal 200
        end
      end
    end

    describe 'when there is specific failure' do
      describe 'with unescaped data' do
        describe 'the index page' do
          before do
            create_sample_failure(args: ['<h1>omg</h1>'], error_message: '<p>wow</p>', error_class: '<script>alert("xss")</script>ArgumentError')
            get '/failures'
          end

          it 'can escape arguments' do
            _(last_response.body).must_match(/&quot;&lt;h1&gt;omg&lt;\/h1&gt;&quot;/)
            _(last_response.body).wont_match(/<h1>omg<\/h1>/)
          end

          it 'can escape error message' do
            _(last_response.body).must_match(/&lt;script&gt;alert\(&quot;xss&quot;\)&lt;\/script&gt;ArgumentError: &lt;p&gt;wow&lt;\/p&gt;/)
            _(last_response.body).wont_match(/<script>alert\("xss"\)<\/script>ArgumentError/)
            _(last_response.body).wont_match(/<p>wow<\/p>/)
          end
        end

        describe 'the details page' do
          before do
            @failure = create_sample_failure(
              args: ['<h1>omg</h1>', '<script>alert("xss2")</script>'], 
              error_message: '<p>wow</p>', 
              error_class: '<script>alert("xss")</script>ArgumentError'
            )
            get "/failures/#{build_param_key(@failure)}"
          end

          it 'can escape error class' do
            _(last_response.status).must_equal 200
            _(last_response.body).must_match(/&lt;script&gt;alert\(&quot;xss&quot;\)&lt;\/script&gt;ArgumentError/)
            _(last_response.body).wont_match(/<script>alert\("xss"\)<\/script>ArgumentError/)
          end

          it 'can escape error message' do
            _(last_response.status).must_equal 200
            _(last_response.body).must_match(/&lt;p&gt;wow&lt;\/p&gt;/)
            _(last_response.body).wont_match(/<p>wow<\/p>/)
          end

          it 'can escape arguments' do
            _(last_response.status).must_equal 200
            _(last_response.body).must_match(/&quot;&lt;h1&gt;omg&lt;\/h1&gt;&quot;/)
            # _(last_response.body).must_match(/&quot;&lt;script&gt;alert\(&quot;xss2&quot;\)&lt;\/script&gt;&quot;/)
            _(last_response.body).wont_match(/<h1>omg<\/h1>/)
            _(last_response.body).wont_match(/<script>alert\("xss2"\)<\/script>/)
          end
        end
      end

      describe 'with deprecated payload' do
        before do
          create_sample_failure(args: nil, payload: { args: ['bob', 5] })
          get '/failures'
        end

        it 'should be successful' do
          _(last_response.status).must_equal 200
        end
      end

      describe 'with deprecated timestamp' do
        before do
          create_sample_failure(failed_at: Time.now.strftime('%Y-%m-%dT%H:%M:%SZ'))
          get '/failures'
        end

        it 'should be successful' do
          _(last_response.status).must_equal 200
        end
      end
    end

    def create_sample_failure(data = {})
      failed_at = Time.now.utc.to_i - 10000
      enqueued_at = failed_at - 1000

      data = {
        :queue => 'default',
        :class => 'HardWorker',
        :args  => ['bob', 5],
        :jid   => SecureRandom.hex(12),
        :enqueued_at     => failed_at.to_f,
        :failed_at       => enqueued_at.to_f,
        :error_class     => 'ArgumentError',
        :error_message   => 'Some new message',
        :error_backtrace => ["path/file1.rb", "path/file2.rb"]
      }.merge(data)

      # Store the score so we can use it for retrieving the failure later
      score = failure_score

      Sidekiq.redis do |c|
        c.multi do
          c.zadd(Sidekiq::Failures::LIST_KEY, score, Sidekiq.dump_json(data))
          c.set("stat:failed", 1)
        end
      end

      # Update data with the score used so tests can reference it
      data[:score] = score
      data
    end

    def build_param_key(failure)
      "#{failure[:score]}-#{failure[:jid]}"
    end

    def failed_count
      Sidekiq.redis { |c| c.get("stat:failed") }
    end

    def failure_score
      Time.now.to_f
    end
  end
end
