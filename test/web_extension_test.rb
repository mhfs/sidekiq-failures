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
      last_response.body.must_match /Sidekiq is idle/
      last_response.body.must_match /Failures/
    end

    it 'can display failures page' do
      get '/failures'
      last_response.status.must_equal 200
      last_response.body.must_match /Failed Jobs/
    end
  end
end
