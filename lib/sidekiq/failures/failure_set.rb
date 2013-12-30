module Sidekiq
  module Failures
    class FailureSet < Sidekiq::SortedSet
      def initialize
        super LIST_KEY
      end

      def retry_all_failures
        while size > 0
          each(&:retry_failure)
        end
      end
    end
  end
end
