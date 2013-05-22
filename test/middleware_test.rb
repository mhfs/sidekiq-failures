require "test_helper"

module Sidekiq
  module Failures
    describe "Middleware" do
      before do
        $invokes = 0
        @boss = MiniTest::Mock.new
        @processor = ::Sidekiq::Processor.new(@boss)
        Sidekiq.server_middleware {|chain| chain.add Sidekiq::Failures::Middleware }
        Sidekiq.redis = REDIS
        Sidekiq.redis { |c| c.flushdb }
        Sidekiq.instance_eval { @failures_default_mode = nil }
      end

      TestException = Class.new(StandardError)
      ShutdownException = Class.new(Sidekiq::Shutdown)

      class MockWorker
        include Sidekiq::Worker

        def perform(args)
          $invokes += 1
          raise ShutdownException.new if args == "shutdown"
          raise TestException.new("failed!")
        end
      end

      it 'raises an error when failures_default_mode is configured incorrectly' do
        assert_raises ArgumentError do
          Sidekiq.failures_default_mode = 'exhaustion'
        end
      end

      it 'defaults failures_default_mode to all' do
        assert_equal :all, Sidekiq.failures_default_mode
      end

      it 'records all failures by default' do
        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'])

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      it 'records all failures if explicitly told to' do
        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => true)

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      it "doesn't record internal shutdown failure" do
        msg = create_work('class' => MockWorker.to_s, 'args' => ['shutdown'], 'failures' => true)

        assert_equal 0, failures_count

        actor = MiniTest::Mock.new
        actor.expect(:processor_done, nil, [@processor])
        @boss.expect(:async, actor, [])
        @processor.process(msg)
        @boss.verify

        assert_equal 0, failures_count
        assert_equal 1, $invokes
      end

      it "doesn't record failure if failures disabled" do
        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => false)

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 0, failures_count
        assert_equal 1, $invokes
      end

      it "doesn't record failure if going to be retired again and configured to track exhaustion by default" do
        Sidekiq.failures_default_mode = :exhausted

        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'] )

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 0, failures_count
        assert_equal 1, $invokes
      end


      it "doesn't record failure if going to be retired again and configured to track exhaustion" do
        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'], 'failures' => 'exhausted')

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 0, failures_count
        assert_equal 1, $invokes
      end

      it "records failure if failing last retry and configured to track exhaustion" do
        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'], 'retry_count' => 24, 'failures' => 'exhausted')

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      it "records failure if failing last retry and configured to track exhaustion by default" do
        Sidekiq.failures_default_mode = 'exhausted'

        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'], 'retry_count' => 24)

        assert_equal 0, failures_count

        assert_raises TestException do
          @processor.process(msg)
        end

        assert_equal 1, failures_count
        assert_equal 1, $invokes
      end

      it "remove old failures when max_failure_count has been reached" do
        Sidekiq.max_failures_count = 2

        msg = create_work('class' => MockWorker.to_s, 'args' => ['myarg'])

        assert_equal 0, failures_count
        
        3.times do
          assert_raises TestException do
            ::Sidekiq::Processor.new(MiniTest::Mock.new).process(msg)
          end
        end
        assert_equal 2, failures_count
      end

      def failures_count
        Sidekiq.redis { |conn|conn.llen('failed') } || 0
      end

      def create_work(msg)
        Sidekiq::BasicFetch::UnitOfWork.new('default', Sidekiq.dump_json(msg))
      end
    end
  end
end
