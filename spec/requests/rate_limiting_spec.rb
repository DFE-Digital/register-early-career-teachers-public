RSpec.describe "Rack::Attack" do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:ip) { "1.2.3.4" }
  let(:other_ip) { "9.8.7.6" }

  before do
    set_request_ip(ip)
  end

  ['/otp-sign-in', '/otp-sign-in/code', '/sign-in', '/otp-sign-in/code'].each do |protected_route|
    context "when requesting protected route #{protected_route}" do
      let(:path) { protected_route }

      it_behaves_like "a rate limited endpoint", "protected routes (OTP)" do
        def perform_request
          get path, headers: { REMOTE_ADDR: request_ip }
        end

        def change_condition
          set_request_ip(other_ip)
        end
      end
    end
  end

  context "rate limit /api/ endpoints by auth token" do
    before do
      set_api_token(API::TokenManager.create_lead_provider_api_token!(lead_provider:).token)
    end

    it_behaves_like "a rate limited endpoint", "API requests by auth token" do
      def perform_request
        authenticated_api_get(api_v3_statements_path, token: api_token, headers: { REMOTE_ADDR: request_ip })
      end

      def change_condition
        set_api_token(API::TokenManager.create_lead_provider_api_token!(lead_provider:).token)
      end
    end
  end

  # TODO: enable when we have guidance and api docs
  # [
  #   "/api/guidance",
  #   "/api/docs/v3",
  # ].each do |public_api_path|
  #   context "when requesting the public API path #{public_api_path}" do
  #     let(:path) { public_api_path }
  #
  #     it_behaves_like "a rate limited endpoint", "public API requests by ip" do
  #       def perform_request
  #         get path
  #       end
  #
  #       def change_condition
  #         set_request_ip(other_ip)
  #       end
  #     end
  #   end
  # end

  context "rate limit all other requests by ip" do
    it_behaves_like "a rate limited endpoint", "All other requests by ip" do
      def perform_request
        get(ab_landing_path, headers: { REMOTE_ADDR: request_ip })
      end

      def change_condition
        set_request_ip(other_ip)
      end
    end
  end

  def set_request_ip(request_ip)
    @request_ip = request_ip
  end

  def set_api_token(token)
    @api_token = token
  end

  attr_reader :request_ip, :api_token
end
