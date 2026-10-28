RSpec.describe "API request logging", type: :request do
  let(:lead_provider) { FactoryBot.create(:lead_provider, short_name: "test-provider") }
  let(:token) { API::TokenManager.create_lead_provider_api_token!(lead_provider:).token }
  let(:log_payload) { {} }

  around do |example|
    subscriber = ->(event) { log_payload.merge!(event.payload) }

    ActiveSupport::Notifications.subscribed(subscriber, "process_action.action_controller") do
      example.run
    end
  end

  it "adds the authenticated lead provider's class, ID and short name to the log payload" do
    authenticated_api_get(api_v3_delivery_partners_path, token:)

    expect(response).to have_http_status(:ok)
    expect(log_payload).to include(
      current_user_class: "LeadProvider",
      current_user_id: lead_provider.id,
      current_user_short_name: "test-provider"
    )
  end

  it "sets the lead provider log fields to nil for an unauthenticated request" do
    get api_v3_delivery_partners_path

    expect(response).to have_http_status(:unauthorized)
    expect(log_payload).to include(
      current_user_class: nil,
      current_user_id: nil,
      current_user_short_name: nil
    )
  end
end
