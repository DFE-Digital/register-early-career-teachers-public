RSpec.describe "Admin::DfESignInOrganisationsController", type: :request do
  let!(:dfe_sign_in_organisation) do
    FactoryBot.create(:dfe_sign_in_organisation)
  end

  describe "GET /show" do
    context "when signed in as admin" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get "/admin/organisations/dfe-sign-in/#{dfe_sign_in_organisation.uuid}"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(dfe_sign_in_organisation.uuid)
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/organisations/dfe-sign-in/#{dfe_sign_in_organisation.uuid}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get "/admin/organisations/dfe-sign-in/#{dfe_sign_in_organisation.uuid}"
        expect(response).to redirect_to("/sign-in")
      end
    end
  end
end
