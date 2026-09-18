RSpec.describe "API clients", type: :request do
  let(:redirect_uri) { "http://www.example.com/integration-support/api-client-connection" }
  let(:client_params) do
    { api_oauth_client: { name: "Vendor A", client_id: "client-1", client_secret: "a-known-secret" } }
  end

  before { allow(Rails.application.config).to receive(:enable_api_test_client).and_return(true) }

  it "is only available to admins" do
    get(new_integration_support_api_client_path)
    expect(response).to redirect_to(root_path)

    sign_in_as(:dfe_user, user: FactoryBot.create(:user, :product_team))
    get(new_integration_support_api_client_path)
    expect(response).to have_http_status(:unauthorized)

    expect { post(integration_support_api_clients_path, params: client_params) }.not_to change(API::OAuth::Client, :count)
    expect(response).to have_http_status(:unauthorized)
  end

  context "when signed in as an admin" do
    before { sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin)) }

    describe "GET /integration-support/api-clients/new" do
      it "renders with a known client ID and secret" do
        existing_client = FactoryBot.create(:api_oauth_client)

        get(new_integration_support_api_client_path)

        page = Capybara.string(response.body)
        expect(response).to have_http_status(:ok)
        expect(page).to have_field("Name")
        expect(page).to have_field("Client ID", with: "client-#{existing_client.id + 1}")
        expect(page).to have_field("Client secret", with: "clientSecret-integration-test")
        expect(page).to have_button("Create client")
      end
    end

    describe "POST /integration-support/api-clients" do
      it "creates a client that redirects to the test client" do
        post(integration_support_api_clients_path, params: client_params)

        client = API::OAuth::Client.find_by!(client_id: "client-1")
        expect(response).to redirect_to(new_integration_support_api_client_connection_path(client_id: "client-1"))
        expect(client).to have_attributes(name: "Vendor A", redirect_uris: [redirect_uri], grant_types: %w[authorization_code])
        expect(client.secret_matches?(secret: "a-known-secret")).to be(true)
      end

      it "shows the errors when the client is invalid" do
        FactoryBot.create(:api_oauth_client, name: "Vendor A")

        expect { post(integration_support_api_clients_path, params: client_params) }.not_to change(API::OAuth::Client, :count)

        page = Capybara.string(response.body)
        expect(response).to have_http_status(:unprocessable_content)
        expect(page).to have_css(".govuk-error-summary")
        expect(page).to have_field("Name", with: "Vendor A")
        expect(page).to have_field("Client secret", with: "a-known-secret")
      end
    end
  end
end
