RSpec.describe "Admin::APIClients::ClientSecretRotationsController" do
  let(:client) { FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform") }

  describe "GET /admin/api-clients/:api_client_id/client-secret-rotation/new" do
    subject do
      get new_admin_api_client_client_secret_rotation_path(client)
      response
    end

    context "when signed in as a non-product DfE user" do
      include_context "sign in as DfE user"

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "when signed in as a product team user" do
      include_context "sign in as product_team DfE user"

      it "asks for confirmation" do
        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include("The current client secret will stop working immediately")
      end
    end
  end

  describe "POST /admin/api-clients/:api_client_id/client-secret-rotation" do
    subject do
      post admin_api_client_client_secret_rotation_path(client)
      response
    end

    context "when signed in as a non-product DfE user" do
      include_context "sign in as DfE user"

      it "does not rotate the secret" do
        expect { subject }.not_to(change { client.reload.client_secret_digest })
        expect(subject).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a product team user" do
      include_context "sign in as product_team DfE user"

      it "replaces the secret and shows the new one once" do
        previous_secret = client.client_secret

        expect(subject).to have_http_status(:ok)
        expect(subject.headers["Cache-Control"]).to include("no-store")
        expect(client.reload.secret_matches?(secret: css_select("#client-secret").first["value"])).to be(true)
        expect(client.secret_matches?(secret: previous_secret)).to be(false)
      end
    end
  end
end
