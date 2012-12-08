require "test_helper"

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
      end

      it 'can remove all failures' do
        last_response.body.must_match /HardWorker/

        post '/failures/remove'
        last_response.status.must_equal 302
        last_response.location.must_match /failures$/

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match /No failed jobs found/
      end

      it 'can reset failures stats' do
        last_response.body.must_match /HardWorker/

        post '/failures/remove'
        Sidekiq.redis do |redis|
          assert_equal "0", redis.get("stat:failed")
        end
      end

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

      Sidekiq.redis { |conn| conn.rpush(:failed, Sidekiq.dump_json(data)) }
    end
  end
end
