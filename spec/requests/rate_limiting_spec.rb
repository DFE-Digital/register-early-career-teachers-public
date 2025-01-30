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

  xit 'POST /otp-sign-in'
  xit 'POST /otp-sign-in/verify'
end
