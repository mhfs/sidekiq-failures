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

      def fetch(score, jid = nil)
        elements = Sidekiq.redis do |conn|
          conn.zrangebyscore(LIST_KEY, score, score)
        end

        ret_val = elements.inject([]) do |result, element|
          entry = SortedEntry.new(self, score, element)
          if jid
            result << entry if entry.jid == jid
          else
            result << entry
          end
          result
        end
        ret_val
      end

      def clear
        Sidekiq.redis do |conn|
          conn.del(LIST_KEY)
        end
      end

      def each(&block)
        initial_size = @_size
        offset_size = 0
        page = -1
        page_size = 50

        loop do
          range_start = page * page_size + offset_size
          range_end   = page * page_size + offset_size + (page_size - 1)
          elements = Sidekiq.redis do |conn|
            conn.zrange LIST_KEY, range_start, range_end, :with_scores => true
          end
          break if elements.empty?
          page -= 1
          elements.each do |element, score|
            block.call SortedEntry.new(self, score, element)
          end
          offset_size = initial_size - @_size
        end
      end

      def delete(score, jid = nil)
        if jid
          elements = Sidekiq.redis do |conn|
            conn.zrangebyscore(LIST_KEY, score, score)
          end

          elements_with_jid = elements.map do |element|
            message = Sidekiq.load_json(element)

            if message["jid"] == jid
              _, @_size = Sidekiq.redis do |conn|
                conn.multi do
                  conn.zrem(LIST_KEY, element)
                  conn.zcard LIST_KEY
                end
              end
            end
          end
          elements_with_jid.count != 0
        else
          count, @_size = Sidekiq.redis do |conn|
            conn.multi do
              conn.zremrangebyscore(LIST_KEY, score, score)
              conn.zcard LIST_KEY
            end
          end
          count != 0
        end
      end
    end
  end
end
