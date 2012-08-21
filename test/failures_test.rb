require "test_helper"

module Sidekiq
  describe "Failures" do
    it "returns version number" do
      Failures::VERSION.must_equal "0.0.1.pre"
    end
  end
end
