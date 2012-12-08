require "test_helper"

module Sidekiq
  module Failures
    describe "Middleware" do
      before do
        $invokes = 0
        boss = MiniTest::Mock.new
        @processor = ::Sidekiq::Processor.new(boss)
        Sidekiq.server_middleware {|chain| chain.add Sidekiq::Failures::Middleware }
        Sidekiq.redis = REDIS
        Sidekiq.redis { |c| c.flushdb }
      end

      TestException = Class.new(StandardError)

      class MockWorker
        include Sidekiq::Worker

        def perform(args)
          $invokes += 1
          raise TestException.new("failed!")
        end
      end

      it 'records all failures by default' do
        msg = create_message('class' => MockWorker.to_s, 'args' => ['myarg'])

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      it 'records all failures if explicitly told to' do
        msg = create_message('class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => true)

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      it "doesn't record failure if failures disabled" do
        msg = create_message('class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => false)

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        assert_equal 0, failures_count
        assert_equal 1, $invokes
      end

      it "doesn't record failure if going to be retired again and configured to track exhaustion" do
        msg = create_message('class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => 'exhausted')

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        assert_equal 0, failures_count
        assert_equal 1, $invokes
      end

      it "records failure if failing last retry and configured to track exhaustion" do
        msg = create_message('class' => MockWorker.to_s, 'args' => ['myarg'], 'retry_count' => 24, 'failures' => 'exhausted')

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg, 'default')
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      def failures_count
        Sidekiq.redis { |conn|conn.llen('failed') } || 0
      end

      def create_message(params)
        Sidekiq.dump_json(params)
      end
    end
  end
end
