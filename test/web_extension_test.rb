require "test_helper"
require "sidekiq/web"

module Sidekiq
  describe "WebExtension" do
    include Rack::Test::Methods

    def app
      Sidekiq::Web
    end

    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis {|c| c.flushdb }
    end

    it 'can display home with failures tab' do
      get '/'

      last_response.status.must_equal 200
      last_response.body.must_match /Sidekiq/
      last_response.body.must_match /Failures/
    end

    it 'can display failures page without any failures' do
      get '/failures'
      last_response.status.must_equal 200
      last_response.body.must_match /Failed Jobs/
      last_response.body.must_match /No failed jobs found/
    end

    describe 'when there are failures' do
      before do
        create_sample_failure
        get '/failures'
      end

      it 'should be successful' do
        last_response.status.must_equal 200
      end

      it 'can display failures page with failures listed' do
        last_response.body.must_match /Failed Jobs/
        last_response.body.must_match /HardWorker/
        last_response.body.must_match /ArgumentError/
        last_response.body.wont_match /No failed jobs found/
      end

      it 'has the clear all form and action' do
        last_response.body.must_match /failures\/remove/
        last_response.body.must_match /method=\"post/
        last_response.body.must_match /Clear All/
        last_response.body.must_match /reset failed counter/
      end

      it 'can remove all failures without clearing counter' do
        assert_equal failed_count, "1"

        last_response.body.must_match /HardWorker/

        post '/failures/remove'
        last_response.status.must_equal 302
        last_response.location.must_match /failures$/

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match /No failed jobs found/

        assert_equal failed_count, "1"
      end

      it 'can remove all failures and clear counter' do
        assert_equal failed_count, "1"

        last_response.body.must_match /HardWorker/

        post '/failures/remove', counter: "true"
        last_response.status.must_equal 302
        last_response.location.must_match /failures$/

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match /No failed jobs found/

        assert_equal failed_count, "0"
      end
    end

    it 'requeues failed jobs' do
      Sidekiq.redis do |c|
        c.multi do
          3.times do |i|
            c.rpush("failed", Sidekiq.dump_json(:payload => {:class => "FooBar", :args => ["foo", i]}, :queue => "priority#{i}"))
          end
        end
      end

      post "/failures/retries", ids: ["0", "2"]

      job = Sidekiq.redis {|c| Sidekiq.load_json(c.lpop("failed")) }
      assert_equal job, {"payload" => {"class" => "FooBar", "args" => ["foo", 1]}, "queue" => "priority1"}

      job = Sidekiq.redis {|c| Sidekiq.load_json(c.lpop("queue:priority0")) }
      assert_equal job["args"], ["foo", 0]

      job = Sidekiq.redis {|c| Sidekiq.load_json(c.lpop("queue:priority2")) }
      assert_equal job["args"], ["foo", 2]
    end

    def create_sample_failure
      data = {
        :failed_at => Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
        :payload => { :args => ["bob", 5] },
        :exception => "ArgumentError",
        :error => "Some new message",
        :backtrace => ["path/file1.rb", "path/file2.rb"],
        :worker => 'HardWorker',
        :queue => 'default'
      }

      Sidekiq.redis do |c|
        c.multi do
          c.rpush("failed", Sidekiq.dump_json(data))
          c.set("stat:failed", 1)
        end
      end
    end

    def failed_count
      Sidekiq.redis { |c| c.get("stat:failed") }
    end
  end
end
