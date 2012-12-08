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

        def perform(args)
          $invokes += 1
          raise TestException.new("failed!")
        end
      end

      it 'records all failures by default' do
        msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'args' => ['myarg'] })

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        Sidekiq.redis { |conn| assert_equal 1, conn.llen('failed') || 0 }

        assert_equal 1, $invokes
      end

      it 'records all failures if explicitly told to' do
        msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => true })

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        Sidekiq.redis { |conn| assert_equal 1, conn.llen('failed') || 0 }

        assert_equal 1, $invokes
      end

      it "doesn't record failure if failures disabled" do
        msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => false })

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_equal 1, $invokes
      end

      it "doesn't record failure if going to be retired again and configured to track exhaustion" do
        msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => 'exhausted' })

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        Sidekiq.redis { |conn| assert_equal 0, conn.llen('failed') || 0 }

        assert_equal 1, $invokes
      end

      it "records failure if failing last retry and configured to track exhaustion" do
        msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'args' => ['myarg'], 'retry_count' => 24, 'failures' => 'exhausted' })

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
