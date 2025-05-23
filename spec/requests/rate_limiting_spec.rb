RSpec.describe "Rack::Attack" do
  include ActiveSupport::Testing::TimeHelpers
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rack::Attack.cache).to receive(:store) { memory_store }
    Rack::Attack.reset!
    Rack::Attack.enabled = true
  end

  after do
    Rack::Attack.enabled = false
  end

  ['/otp-sign-in', '/otp-sign-in/code', '/sign-in', '/otp-sign-in/code'].each do |protected_route|
    it "allows 5 requests in quick succession #{protected_route}" do
      5.times do
        get(protected_route)
        expect(response).to have_http_status(:ok)
      end
    end

    it 'blocks the 6th' do
      5.times { get(protected_route) }
      get(protected_route)
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'allows more requests after 20 seconds' do
      5.times { get(protected_route) }
      travel(20.seconds)
      get(protected_route)
      expect(response).to have_http_status(:ok)
    end
  end

  context "rate limit /api/ endpoints by auth token" do
    let(:headers) { { Authorization: "Bearer TEST_TOKEN" } }

    it "throttles over 1000 requests within 5 minutes" do
      freeze_time do
        1000.times do
          get(api_v3_statements_path, headers:)
          expect(response).to have_http_status(:method_not_allowed) # change to :ok when /api/v3/statements is ready
        end

        5.times do
          get(api_v3_statements_path, headers:)
          expect(response).to have_http_status(:too_many_requests)
        end
      end

      # After 5 minutes
      travel(5.minutes) do
        5.times do
          get(api_v3_statements_path, headers:)
          expect(response).to have_http_status(:method_not_allowed) # change to :ok when /api/v3/statements is ready
        end
      end
    end
  end
end
