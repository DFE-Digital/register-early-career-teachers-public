RSpec.describe "Admin::InductionPlatformsController", type: :request do
  let(:induction_platform) { FactoryBot.create(:api_oauth_client) }

  describe "GET /admin/organisations/induction-platforms" do
    context "when signed in as a DfE user" do
      include_context "sign in as DfE user"

      it "lists the induction platforms alphabetically" do
        FactoryBot.create(:api_oauth_client, name: "Beta Induction Platform")
        FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform")

        get "/admin/organisations/induction-platforms"

        expect(response).to have_http_status(:success)
        expect(response.body.index("Alpha Induction Platform")).to be < response.body.index("Beta Induction Platform")
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/organisations/induction-platforms"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /admin/organisations/induction-platforms/:id" do
    context "when signed in as a DfE user" do
      include_context "sign in as DfE user"

      def create_authorization(appropriate_body_name, *traits, client: induction_platform)
        FactoryBot.create(:api_oauth_authorization, *traits,
                          client:,
                          appropriate_body_period: FactoryBot.create(:appropriate_body_period, name: appropriate_body_name))
      end

      it "lists appropriate bodies alphabetically" do
        create_authorization("Zeta Body", :with_token)
        create_authorization("Alpha Body", :with_token)

        get "/admin/organisations/induction-platforms/#{induction_platform.id}"

        expect(response).to have_http_status(:success)
        expect(response.body.index("Alpha Body")).to be < response.body.index("Zeta Body")
      end

      it "only includes active authorisations for this platform" do
        create_authorization("Active Body", :with_token)
        create_authorization("Revoked Body", :with_token, :revoked)
        create_authorization("Expired Body", :with_expired_token)
        create_authorization("Unexchanged Body")
        create_authorization("Other Platform Body", :with_token, client: FactoryBot.create(:api_oauth_client))

        get "/admin/organisations/induction-platforms/#{induction_platform.id}"

        expect(response.body).to include("Active Body")
        expect(response.body).not_to include("Revoked Body", "Expired Body", "Unexchanged Body", "Other Platform Body")
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/organisations/induction-platforms/#{induction_platform.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
