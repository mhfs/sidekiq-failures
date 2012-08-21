module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)
        app.helpers do
          def find_template(view, *a, &b)
            dir = File.expand_path("../views/", __FILE__)
            super(dir, *a, &b)
            super
          end
        end

        app.get "/failures" do
          slim :failures
        end
      end
    end
  end
end
