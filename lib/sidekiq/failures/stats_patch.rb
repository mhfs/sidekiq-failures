# frozen_string_literal: true

module Sidekiq
  module Failures
    module StatsPatch
      def failed
        Sidekiq.redis { |r| r.zcard("failed") }
      end
    end
  end
end
