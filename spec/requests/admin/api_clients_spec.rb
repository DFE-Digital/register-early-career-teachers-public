RSpec.describe "Admin::APIClientsController" do
  let(:client) { FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform", redirect_uris: %w[https://alpha.example.com/callback https://alpha.example.com/another-callback]) }

  describe "GET /admin/api-clients" do
    subject do
      get admin_api_clients_path
      response
    end

    context "when not signed in" do
      it { is_expected.to redirect_to(sign_in_path) }
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "when signed in as a non-product DfE user" do
      include_context "sign in as DfE user"

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "when signed in as a product team user" do
      include_context "sign in as product_team DfE user"

      it "lists the clients alphabetically with their client IDs" do
        beta_platform = FactoryBot.create(:api_oauth_client, name: "Beta Induction Platform")
        client

        expect(subject).to have_http_status(:ok)
        expect(subject.body.index("Alpha Induction Platform")).to be < subject.body.index("Beta Induction Platform")
        expect(subject.body).to include(client.client_id, beta_platform.client_id)
      end
    end
  end

  describe "GET /admin/api-clients/:id" do
    include_context "sign in as product_team DfE user"

    it "shows the client details without the secret" do
      get admin_api_client_path(client)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        client.client_id,
        "https://alpha.example.com/callback",
        "https://alpha.example.com/another-callback",
        "Not available to view"
      )
    end
  end

  describe "GET /admin/api-clients/new" do
    include_context "sign in as product_team DfE user"

    it "shows the form" do
      get new_admin_api_client_path

      expect(response).to have_http_status(:ok)
      expect(css_select("label[for=api-oauth-client-name-field]").text).to include("Client name")
      expect(css_select("input[name='api_oauth_client[redirect_uris][]']").size).to eq(3)
    end
  end

  describe "POST /admin/api-clients" do
    include_context "sign in as product_team DfE user"

    let(:redirect_uris) { ["https://beta.example.com/callback", "https://beta.example.com/another-callback", ""] }

    def create_client(name: "Beta Induction Platform")
      post admin_api_clients_path, params: { api_oauth_client: { name:, redirect_uris: } }
    end

    it "creates the client and shows its credentials once" do
      expect { create_client }.to change(API::OAuth::Client, :count).by(1)

      client = API::OAuth::Client.last

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(client).to have_attributes(name: "Beta Induction Platform", redirect_uris: redirect_uris.compact_blank, grant_types: %w[authorization_code])
      expect(css_select("#client-id").first["value"]).to eq(client.client_id)
      expect(client.secret_matches?(secret: css_select("#client-secret").first["value"])).to be(true)
      expect(css_select("main button[hidden]").map { it.text.squish }).to contain_exactly("Copy client ID", "Copy client secret")
    end

    context "when the client is invalid" do
      let(:redirect_uris) { ["not a uri", ""] }

      it "shows the errors and keeps what was entered" do
        expect { create_client(name: "") }.not_to change(API::OAuth::Client, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(css_select(".govuk-error-summary").text).to include("Enter a name", "Enter redirect URIs in the correct format, like https://example.com/callback")
        expect(css_select("input[name='api_oauth_client[redirect_uris][]']").map { it["value"] }).to include("not a uri")
      end
    end
  end

  describe "GET /admin/api-clients/:id/edit" do
    context "when signed in as a non-product DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        get edit_admin_api_client_path(client)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a product team user" do
      include_context "sign in as product_team DfE user"

      it "shows the current details with room for another redirect URI" do
        get edit_admin_api_client_path(client)

        expect(response).to have_http_status(:ok)
        expect(css_select("#api-oauth-client-name-field").first["value"]).to eq("Alpha Induction Platform")
        expect(css_select("input[name='api_oauth_client[redirect_uris][]']").map { it["value"] }).to eq([
          "https://alpha.example.com/callback",
          "https://alpha.example.com/another-callback",
          nil
        ])
      end
    end
  end

  describe "PATCH /admin/api-clients/:id" do
    def update_client(name: "Gamma Induction Platform", redirect_uris: ["https://alpha.example.com/new-callback", "https://alpha.example.com/callback", ""])
      patch admin_api_client_path(client), params: { api_oauth_client: { name:, redirect_uris: } }
    end

    context "when signed in as a non-product DfE user" do
      include_context "sign in as DfE user"

      it "does not change the client" do
        expect { update_client }.not_to(change { client.reload.attributes })
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a product team user" do
      include_context "sign in as product_team DfE user"

      it "updates the name and redirect URIs without changing the credentials" do
        expect { update_client }.not_to(change { client.reload.slice(:client_id, :client_secret_digest) })

        expect(response).to redirect_to(admin_api_client_path(client))
        expect(flash[:alert]).to eq("Client details updated")
        expect(client).to have_attributes(
          name: "Gamma Induction Platform",
          redirect_uris: %w[https://alpha.example.com/new-callback https://alpha.example.com/callback]
        )
      end

      it "shows the errors and keeps what was entered when invalid" do
        expect { update_client(name: "", redirect_uris: ["not a uri"]) }.not_to(change { client.reload.attributes })

        expect(response).to have_http_status(:unprocessable_content)
        expect(css_select(".govuk-error-summary").text).to include("Enter a name", "Enter redirect URIs in the correct format, like https://example.com/callback")
        expect(css_select("input[name='api_oauth_client[redirect_uris][]']").map { it["value"] }).to include("not a uri")
      end
    end
  end
end
