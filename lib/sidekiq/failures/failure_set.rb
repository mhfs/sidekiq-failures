module Sidekiq
  module Failures
    Superclass =
      if defined?(Sidekiq::JobSet)
        Sidekiq::JobSet
      else
        Sidekiq::SortedSet
      end

    class FailureSet < Superclass
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
