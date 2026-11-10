RSpec.describe "Health check" do
  describe "GET /healthcheck" do
    it "returns some JSON describing the application health" do
      get "/healthcheck"

      expect(JSON.parse(response.body)).to eql(
        {
          "commit_sha" => "UNKNOWN",
          "postgresql" => "connected",
          "redis" => "connected",
        }
      )
    end

    context "when the commit SHA is known" do
      before do
        allow(ENV).to receive(:fetch).with("COMMIT_SHA", "UNKNOWN").and_return("abc123def")
      end

      it "returns the commit sha" do
        get "/healthcheck"

        expect(JSON.parse(response.body).fetch("commit_sha")).to eql("abc123def")
      end
    end

    context "when PostgreSQL is not connected" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(PG::ConnectionBad)
      end

      it "returns 'not connected'" do
        get "/healthcheck"

        expect(JSON.parse(response.body).fetch("postgresql")).to eql("not connected")
      end
    end

    describe "Redis" do
      context "when Redis is not connected" do
        before do
          allow(Rails.cache.redis).to receive(:with).and_raise(Redis::CannotConnectError)
        end

        it "returns 'not connected'" do
          get "/healthcheck"

          expect(JSON.parse(response.body).fetch("redis")).to eql("cannot connect")
        end
      end

      context "when Redis errors while connected" do
        before do
          allow(Rails.cache.redis).to receive(:with).and_raise(Redis::BaseError)
        end

        it "returns 'error connecting'" do
          get "/healthcheck"

          expect(JSON.parse(response.body).fetch("redis")).to eql("error connecting")
        end
      end

      context "when Redis isn't used" do
        before do
          allow(Rails.cache).to receive(:is_a?).with(ActiveSupport::Cache::RedisCacheStore).and_return(false)
        end

        it "returns 'not used'" do
          get "/healthcheck"

          expect(JSON.parse(response.body).fetch("redis")).to eql("not used")
        end
      end
    end
  end
end
