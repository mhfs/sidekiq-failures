module Sidekiq
  module Failures
    module Paginator
      def paginate(key, pageidx=1, page_size=25)
        current_page = pageidx.to_i < 1 ? 1 : pageidx.to_i
        pageidx = current_page - 1
        total_size = 0
        items = []
        starting = pageidx * page_size
        ending = starting + page_size - 1

        Sidekiq.redis do |conn|
          total_size = conn.zcard(key)
          items = conn.zrevrange(key, starting, ending, :with_scores => true)
        end

        [current_page, total_size, items]
      end
    end
  end
end
