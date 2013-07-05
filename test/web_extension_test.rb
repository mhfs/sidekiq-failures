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
      last_response.body.must_match(/Sidekiq/)
      last_response.body.must_match(/Failures/)
    end

    it 'can display failures page without any failures' do
      get '/failures'
      last_response.status.must_equal 200
      last_response.body.must_match(/Failures/)
      last_response.body.must_match(/NoFailuresFound/)
    end

    describe 'when there is failure' do
      before do
        create_sample_failure
        get "/failures/#{failure_score}"
      end

      it 'should be successful' do
        last_response.status.must_equal 200
      end

      it 'can didplay failure page' do
        last_response.body.must_match(/Job/)
        last_response.body.must_match(/HardWorker/)
        last_response.body.must_match(/ArgumentError/)
        last_response.body.must_match(/file1/)
      end

      it 'can delete failure' do
        last_response.body.must_match(/HardWorker/)

        post "/failures/#{failure_score}", :delete => 'Delete'
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)

        get "/failures/#{failure_score}"
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)
      end

      it 'can retry failure' do
        last_response.body.must_match(/HardWorker/)

        post "/failures/#{failure_score}", :retry => 'Retry Now'
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)

        get "/failures/#{failure_score}"
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)
      end
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
        last_response.body.must_match(/Failures/)
        last_response.body.must_match(/HardWorker/)
        last_response.body.must_match(/bob/)
        last_response.body.wont_match(/NoFailuresFound/)
      end

      it 'has the delete all form and action' do
        last_response.body.must_match(/failures\/all\/delete/)
        last_response.body.must_match(/method=\"post/)
        last_response.body.must_match(/Delete All/)
      end

      it 'can delete all failures' do
        assert_equal failed_count, "1"

        last_response.body.must_match(/HardWorker/)

        post '/failures/all/delete'
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match(/NoFailuresFound/)
      end

      it 'has the retry all form and action' do
        last_response.body.must_match(/failures\/all\/retry/)
        last_response.body.must_match(/method=\"post/)
        last_response.body.must_match(/Retry All/)
      end

      it 'can retry all failures' do
        assert_equal failed_count, "1"

        last_response.body.must_match(/HardWorker/)

        post '/failures/all/retry'
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match(/NoFailuresFound/)
      end

      it 'can delete failure from the list' do
        assert_equal failed_count, "1"

        last_response.body.must_match(/HardWorker/)

        post '/failures', { :key => [failure_score], :delete => 'Delete' }
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match(/NoFailuresFound/)
      end

      it 'can retry failure from the list' do
        assert_equal failed_count, "1"

        last_response.body.must_match(/HardWorker/)

        post '/failures', { :key => [failure_score], :retry => 'Retry Now' }
        last_response.status.must_equal 302
        last_response.location.must_match(/failures/)

        get '/failures'
        last_response.status.must_equal 200
        last_response.body.must_match(/NoFailuresFound/)
      end
    end

    def create_sample_failure
      data = {
        :queue => 'default',
        :class => 'HardWorker',
        :args => ["bob", 5],
        :jid => 1,
        :enqueued_at => Time.now.utc.to_f,
        :failed_at => Time.now.utc.to_f,
        :error_class => 'ArgumentError',
        :error_message => 'Some new message',
        :error_backtrace => ["path/file1.rb", "path/file2.rb"]
      }

      Sidekiq.redis do |c|
        c.multi do
          c.zadd("failure", failure_score, Sidekiq.dump_json(data))
          c.set("stat:failed", 1)
        end
      end
    end

    def failed_count
      Sidekiq.redis { |c| c.get("stat:failed") }
    end

    def failure_score
      Time.at(1).to_f
    end
  end
end
