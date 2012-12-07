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

      describe 'record failures on max retries' do
        before do
          Sidekiq::Failures.record_after_max_retries = true
        end

        after do
          Sidekiq::Failures.record_after_max_retries = nil
        end

        def assert_failure_count count
          Sidekiq.redis { |conn| assert_equal count, conn.llen('failed') || 0 }
        end

        def run_worker retry_count = nil
          assert_failure_count 0
          msg = Sidekiq.dump_json({ 'class' => MockWorker.to_s, 'retry_count' => retry_count, 'args' => ['myarg'] })
          assert_raises TestException do
            @processor.process(msg, 'default')
          end
        end

        describe '1st failure' do

          it 'does not fail the message' do
            run_worker 
            assert_failure_count 0
            assert_equal 1, $invokes
          end

        end

        describe '24th failure' do

          it 'does not fail the message' do
            run_worker 24
            assert_failure_count 0
            assert_equal 1, $invokes
          end

        end

        describe '25th failure' do

          it 'fails the message' do
            run_worker 25
            assert_failure_count 1
            assert_equal 1, $invokes
          end

        end

      end

    end
  end
end
