require "test_helper"

module Sidekiq
  module Failures
    describe "Middleware" do
      TestException = Class.new(StandardError)

      before do
        $invokes = 0
        boss = MiniTest::Mock.new
        @processor = ::Sidekiq::Processor.new(boss)
        Sidekiq.server_middleware {|chain| chain.add Sidekiq::Failures::Middleware }
        Sidekiq.redis = REDIS
        Sidekiq.redis { |c| c.flushdb }
      end

      class MockWorker
        include Sidekiq::Worker
        sidekiq_options :retry => false

        def perform(args)
          $invokes += 1
          raise TestException.new("failed!")
        end
      end

      it 'record failures' do
        msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'args' => ['myarg'] })

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        Sidekiq.redis { |conn| assert_equal 1, conn.llen('failed') || 0 }

        assert_equal 1, $invokes
      end
    end
  end
end
